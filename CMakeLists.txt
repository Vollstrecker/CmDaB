# This file is part of the CmDab Project.
#
# Copyright (c) 2021-2026 Vollstrecker (github@vollstreckernet.de)
#
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
# -----------------------------------------------------------------------------

# =============================================================================
# CmDaB – Configure-time Dependency Bootstrapper
# =============================================================================
#
# This file provides the core functions used by CmDaB to resolve dependencies
# during the CMake configure phase.
#
# CmDaB integrates with CMake via find_package and augments the resolution
# process without replacing it.
#
# -----------------------------------------------------------------------------
# Public Entry Points
# -----------------------------------------------------------------------------
#
#   CmDaB_declare(<Package> ...)
#
#     Declares a package and registers all required metadata.
#
#     Arguments:
#       GIT_REPOSITORY   Source repository for FetchContent
#       GIT_TAG          Revision / branch / tag
#
#       OPTIONS          Key/value pairs applied as cache defaults
#       TEST_OPTIONS     List of test-related cache variables
#       ALIASES          Pairs mapping canonical → upstream targets
#       STATIC_SUFFIX    Suffix for generic static targets (e.g. "static")
#       PLATFORMS        List of allowed platform conditions
#
#     This call also generates the corresponding Config and Find wrappers.
#
#
#   CmDaB_Resolve(<Package>)
#
#     Resolves a package during find_package.
#
#     Behavior:
#       1. Dispatches to <Package>_Handle_Find if present
#       2. Otherwise uses CmDaB_Handle_Find_Generic
#
#
# -----------------------------------------------------------------------------
# Resolution Helpers
# -----------------------------------------------------------------------------
#
#   CmDaB_Handle_Find_Generic(<Package>)
#
#     Generic fallback implementation.
#
#     Behavior:
#       - Attempts to locate the package via find_package
#       - Validates presence of at least one known target
#       - Applies declared options and test configuration
#       - Uses FetchContent if required
#       - Applies declared alias mappings
#
#
# -----------------------------------------------------------------------------
# Prefix Handling
# -----------------------------------------------------------------------------
#
#   CmDaB_Remove_Prefix()
#   CmDaB_Add_Prefix()
#
#     Temporarily remove and re-add CmDaB search paths.
#
#     Required to avoid recursion when calling find_package from within
#     the resolution logic.
#
#
# -----------------------------------------------------------------------------
# Package-specific Hooks
# -----------------------------------------------------------------------------
#
#   <Package>_Handle_Find()
#
#     Optional override for packages requiring custom resolution behavior.
#
#     Responsibilities:
#       - Define required targets (e.g. via components)
#       - Attempt system resolution (respecting CmDaB_Always_Download)
#       - Validate that required targets are present
#       - Configure build options before FetchContent
#       - Call FetchContent_MakeAvailable
#       - Apply aliases as needed
#
#
# -----------------------------------------------------------------------------
# Global Options
# -----------------------------------------------------------------------------
#
#   CmDaB_Always_Download
#     If enabled, skips system discovery and always uses FetchContent
#
#   CmDaB_Build_Tests
#     Default value for all declared TEST_OPTIONS
#
#   CmDaB_PACKAGE_DIR
#     Path to an additional directory containing local packages or overrides
#
# -----------------------------------------------------------------------------
# Notes
# -----------------------------------------------------------------------------
#
# - All resolution happens during configure time
# - find_package remains the only interface exposed to users
# - Upstream targets are preserved; CmDaB only normalizes access
#
# =============================================================================

cmake_minimum_required (VERSION 3.11)

option(CmDaB_Always_Download
  "Always fetch dependencies instead of using system packages"
  OFF
)

option (CmDaB_Build_Tests "Build Tests of all downloaded packages" OFF)

set(CmDaB_PACKAGE_DIR "" CACHE PATH
  "Additional directories containing CmDaB package definitions"
)

macro(CmDaB_Add_Prefix)
  list(PREPEND CMAKE_PREFIX_PATH "${CmDaB_CONFIG_DIR}")
  list(PREPEND CMAKE_MODULE_PATH "${CmDaB_MODULE_DIR}")

  set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
  set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
endmacro()

function(CmDaB_Declare package)
  set(CmDaB_FETCH_KEYS
    GIT_REPOSITORY
    GIT_TAG
  )

  set(CmDaB_META_KEYS
    ALIASES
    NO_STATIC
    PLATFORMS
    STATIC_SUFFIX
    TEST_OPTIONS
    OPTIONS
  )

  cmake_parse_arguments(
    CmDaB
    ""
    "${CmDaB_FETCH_KEYS}"
    "${CmDaB_META_KEYS}"
    ${ARGN}
  )

  if(CmDaB_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "Unhandled argument in ${package}: ${CmDaB_UNPARSED_ARGUMENTS}")
  endif()

  if(CmDaB_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR
      "Missing value in ${package}: ${CmDaB_KEYWORDS_MISSING_VALUES}")
  endif()

  set(fetch_args "")
  foreach(k IN LISTS CmDaB_FETCH_KEYS)
    if(CmDaB_${k})
      list(APPEND fetch_args "${k}" ${CmDaB_${k}})
    endif()
  endforeach()

  FetchContent_Declare(${package}
    ${_fetch_args}
  )

  if(NOT DEFINED CmDaB_${package}_PLATFORMS)
    CmDaB_Write_Config(${package})
    CmDaB_Write_Find_Module(${package})
  else()
    foreach(_cond IN LISTS CmDaB_${package}_PLATFORMS)
      if(${_cond})
        CmDaB_Write_Config(${package})
        CmDaB_Write_Find_Module(${package})
        break()
      endif()
    endforeach()
  endif()

  if(DEFINED CMDAB_NO_STATIC)
    set(_cmdab_${package}_STATIC_SUFFIX FALSE)
  elseif(DEFINED CMDAB_STATIC_SUFFIX)
    set(_cmdab_${package}_STATIC_SUFFIX "${CMDAB_STATIC_SUFFIX}")
  else()
    set(_cmdab_${package}_STATIC_SUFFIX "static")
  endif()
endfunction()

function(CmDaB_Handle_Find_Generic package)
  if(NOT CmDaB_Always_Download)
    CmDaB_Remove_Prefix()

    find_package(${package} QUIET)

    CmDaB_Add_Prefix()

    set(_ok FALSE)

    if(TARGET ${package}::${package})
      set(_ok TRUE)
    endif()

    if(NOT _ok)
      get_property(_aliases GLOBAL PROPERTY CmDaB_${package}_ALIASES)

      if(_aliases)
        foreach(_alias _target IN LISTS _aliases)
          if(TARGET ${_alias} OR TARGET ${_target})
            set(_ok TRUE)
            break()
          endif()
        endforeach()
      endif()
    endif()

    if(_ok)
      return()
    endif()
  endif()

  get_property(_opts GLOBAL PROPERTY CmDaB_${package}_OPTIONS)

  if(_opts)
    foreach(_k _v IN LISTS _opts)
      set(${_k} ${_v} CACHE BOOL "")
    endforeach()
  endif()

  get_property(_tests GLOBAL PROPERTY CmDaB_${package}_TEST_OPTIONS)

  if(_tests)
    foreach(_opt IN LISTS _tests)
      set(${_opt} ${CmDaB_Build_Tests} CACHE BOOL "")
    endforeach()
  endif()

  FetchContent_MakeAvailable(${package})

  get_property(_aliases GLOBAL PROPERTY CmDaB_${package}_ALIASES)

  if(_aliases)
    foreach(_alias _target IN LISTS _aliases)
      if(NOT TARGET ${_alias} AND TARGET ${_target})
        add_library(${_alias} ALIAS ${_target})
      endif()
    endforeach()
  endif()

  set(_suffix "${_cmdab_${package}_STATIC_SUFFIX}")

  if(_suffix)
    if(TARGET ${package}${_suffix}
       AND NOT TARGET ${package}::${package}static)
      add_library(${package}::${package}static ALIAS ${package}${_suffix})
    endif()
  endif()
endfunction()

function(CmDaB_Resolve package)
  if(COMMAND ${package}_Handle_Find)
    cmake_language(CALL ${package}_Handle_Find())
    return()
  endif()

  CmDaB_Handle_Find_Generic(${package})
endfunction()

macro(CmDaB_Remove_Prefix)
  set(_cmdab_saved_prefix "${CMAKE_PREFIX_PATH}")
  set(_cmdab_saved_module "${CMAKE_MODULE_PATH}")

  list(REMOVE_ITEM CMAKE_PREFIX_PATH "${CmDaB_CONFIG_DIR}")
  list(REMOVE_ITEM CMAKE_MODULE_PATH "${CmDaB_MODULE_DIR}")
  set(${CMAKE_FIND_PACKAGE_NAME}_DIR "")
endmacro()

function(CmDaB_Write_Config package)

  set(_dir  "${CmDaB_CONFIG_DIR}/${package}")
  set(_file "${_dir}/${package}Config.cmake")

  file(MAKE_DIRECTORY "${_dir}")

  if(EXISTS "${_file}")
    return()
  endif()

  file(WRITE "${_file}" "
# ============================================================
#  Auto-generated by CmDaB for package: ${package}
# ============================================================

CmDaB_Resolve(${package})
")
endfunction()

function(CmDaB_Write_Find_Module package)

  set(_dir  "${CmDaB_MODULE_DIR}")
  set(_file "${_dir}/Find${package}.cmake")

  file(MAKE_DIRECTORY "${_dir}")

  if(EXISTS "${_file}")
    return()
  endif()

  file(WRITE "${_file}" "
# ============================================================
#  Auto-generated Find Module by CmDaB for package: ${package}
# ============================================================

# ---- warn about legacy usage ----
message(DEPRECATION
  \"CmDaB: 'Find${package}.cmake' was included directly.\n"
  "Use 'find_package(${package})' instead.\"
)

# ---- delegate to config-based resolution ----
find_package(${package} CONFIG QUIET)
")
endfunction()

set(CmDaB_CONFIG_DIR "${CMAKE_BINARY_DIR}/cmdab/configs")
set(CmDaB_CONFIG_DIR "${CMAKE_BINARY_DIR}/cmdab/configs" PARENT_SCOPE)
set(CmDaB_MODULE_DIR "${CMAKE_BINARY_DIR}/cmdab/modules")
set(CmDaB_MODULE_DIR "${CMAKE_BINARY_DIR}/cmdab/modules" PARENT_SCOPE)

CmDaB_Add_Prefix()

if(CmDaB_PACKAGE_DIR)
  file(GLOB _cmdab_user_packages
    "${CmDaB_PACKAGE_DIRS}/*.cmake"
  )

  foreach(_pkg IN LISTS _cmdab_user_packages)
    include("${_pkg}")
  endforeach()
endif()

file(GLOB _cmdab_core_packages
  "${CMAKE_CURRENT_LIST_DIR}/packages/*.cmake"
)

foreach(_pkg IN LISTS _cmdab_core_packages)
  include("${_pkg}")
endforeach()

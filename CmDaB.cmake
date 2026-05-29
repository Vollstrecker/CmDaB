# This file is part of the CmDab Project.
#
# Copyright (c) 2021-2026 Vollstrecker (github@vollstreckernet.de)
#
# Licensed under the MIT License. See LICENSE file in the project for
# full license information.
# https://github.com/Vollstrecker/CmDaB/blob/main/LICENSE
# --------------------------------------------------------------------

#[=======================================================================[.rst:
CmDaB.cmake
------------------

.. only:: html

  .. contents::

Overview
^^^^^^^^

  This module adds an option called DOWNLOAD_AND_BUILD_DEPS to your project.
  If this option is activated by the user, this module will download and
  include the main project files to be used within your project.

#]=======================================================================]

include (CMakeDependentOption)

Find_Package (Git)
cmake_dependent_option (DOWNLOAD_AND_BUILD_DEPS "Get all missing stuff" OFF ${Git_FOUND} OFF)

if (DOWNLOAD_AND_BUILD_DEPS)
  include (FetchContent)

  FetchContent_Declare (
    CmDaB
    GIT_REPOSITORY https://github.com/Vollstrecker/CmDaB.git
    GIT_TAG main)

  FetchContent_GetProperties(CmDaB)

  if (NOT cmdab_POPULATED)
    if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.14)
      FetchContent_MakeAvailable (CmDaB)
    else()
      FetchContent_Populate (CmDaB)

      add_subdirectory (${cmdab_SOURCE_DIR}
                        ${cmdab_BINARY_DIR})
    endif()
  endif()
endif()

# This file is part of the CmDab Project.
#
# Copyright (c) 2021 Vollstrecker (werner@vollstreckernet.de)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 3as published by
# the Free Software Foundation; of the License
#
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, check
# https://github.com/Vollstrecker/CmDaB/blob/main/LICENSE

#[=======================================================================[.rst:
CmDaB
------------------

.. only:: html

  .. contents::

Overview
^^^^^^^^

This module enables you to download packages your sourcecode depends on
while configure-stage of your source. Configuration of the downloaded
packages is done immediately after download. Libs to link against are built
installed along your own project.

You can use any method supported by the :module:`ExternalProject` module.

To use this package in your code, simply include the CmDaB.cmake file
from the root of the repository. It will check for installed git on your system,
and add an option called DOWNLOAD_AND_BUILD_DEPS. You can check if the user
activates this one and then just call CmDaB_install when your checks report a
missing dependency.

The following shows a typical example:

.. code-block:: cmake

  include CmDaB.cmake
  if (NOT LIBUPNP_FOUND AND DOWNLOAD_AND_BUILD_DEPS)
    CmDaB_install ("UPNP")
  endif()

For a list of useable packages look into module-dir of this package
command like so:

Commands
^^^^^^^^

Declaring Content Details
"""""""""""""""""""""""""

.. command:: CmDaB_declare

  .. code-block:: cmake

    CmDaB_declare (<name> <contentOptions>...)

  The ``CmDaB_declare()`` function records the options that describe
  how to populate the specified content, but if such details have already
  been recorded earlier in this project (regardless of where in the project
  hierarchy), this and all later calls for the same content ``<name>`` are
  ignored.  This "first to record, wins" approach is what allows hierarchical
  projects to have parent projects override content details of child projects.

  This basically a reimplementation of :command:`FetchContent_Declare` it is
  mainly used in the package-definitions in the modules-dir. You can use it in
  your code to define packages that are not included here, although FetchContent
  would do the same for you in this case.

  The content ``<name>`` can be any string without spaces, but good practice
  would be to use only letters, numbers and underscores.  The name will be
  treated case-insensitively and it should be obvious for the content it
  represents, often being the name of the child project or the value given
  to its top level :command:`project` command.

  For well-known public projects, the name should generally be the official
  name of the project.  Choosing an unusual name makes it unlikely that other
  projects needing that same content will use the same name, leading to
  the content being populated multiple times.

  The ``<contentOptions>`` can be any of the download or update/patch options
  that the :command:`FetchContent_Declare` command understands.

  In most cases, ``<contentOptions>`` will just be a couple of options defining
  the download method and method-specific details like a commit tag or archive
  hash.  For example:

  .. code-block:: cmake

  CmDaB_declare (
    UPNP
    GIT_REPOSITORY https://github.com/pupnp/pupnp.git
  )

  In Addition ``CmDaB_declare()`` understands commands to limit the package to
  certain plattforms. As the whole package is always in development, you can
  always ask for new options on github, if you want something for your package
  added.

  Currently supported:
    PLATFORMS - Use this to limit where your package is available in the form
    like you would check for this plattform using if.

      .. code-block:: cmake

      PLATFORMS WIN32 - equals to if(${WIN32}) ....

Populating The Content
""""""""""""""""""""""

.. command:: CmDaB_install

  .. code-block:: cmake

    CmDaB_install (<name>)

  This function does the actual downloading step. It checks if the package is
  available at all, and for your explicit plattform. If yes it will clone
  the repository into _deps subfolder of your build-tree and runs the
  CMakeLists.txt in there.

  If your project needs some additional or optional features of the package,
  just set the variables that are used by the project like you would do when
  building it from the commandline before calling this function.

  This function does nothing on success. If you order a non-existing package, or
  one that doesn't work on your current plattform, this will be an error. If there
  are problems while configuring the downloaded package, the CMakeLists.txt of this
  package has to deal with it. If no error occurs, you can just use everything like
  it would be in your source-tree.

#]=======================================================================]

cmake_minimum_required (VERSION 3.11)
include (FetchContent)

function (CmDaB_declare package)
	set (propertyName "CmDaB_${package}_savedDetails")
	get_property (alreadyDefined GLOBAL PROPERTY ${propertyName} DEFINED)

	if (NOT alreadyDefined)
		define_property (GLOBAL PROPERTY ${propertyName}
			BRIEF_DOCS "Internal package details for CmDaB"
			FULL_DOCS  "Details used by CmDaB for managing ${package}"
		)

		set_property(GLOBAL PROPERTY ${propertyName} ${ARGN})
	endif()
endfunction()

#################################################################################
# This function parses all options for the given package                        #
# The keywords regarding package downloading are given back in the var pkg_info #
# CmDaB specific keywords as listed above are in vars named CmDaB_${KEYWORD}    #
#################################################################################
function (CmDaB_get_package_info package)
	set (propertyName "CmDaB_${package}_savedDetails")
	get_property (alreadyDefined GLOBAL PROPERTY ${propertyName} DEFINED)

	if (NOT alreadyDefined)
		message (FATAL_ERROR "Installation requested for not known package: ${package}")
	endif()

	get_property (contentDetails GLOBAL PROPERTY ${propertyName})

	set (oVA GIT_REPOSITORY)
	set (mVA PLATFORMS)

	cmake_parse_arguments (CmDaB "" "${oVA}" "${mVA}" ${contentDetails})

	if (CmDaB_UNPARSED_ARGUMENTS)
		message (FATAL_ERROR "Unhandled Statement in description of package: ${package}: ${CmDaB_UNPARSED_ARGUMENTS}")
	elseif (CmDaB_KEYWORDS_MISSING_VALUES)
		message (FATAL_ERROR "Keyword without value given in description of package: ${package}: ${CmDaB_KEYWORDS_MISSING_VALUES}")
	endif()

	foreach (optName IN LISTS oVA mVA)
		if (optName STREQUAL "GIT_REPOSITORY")
			list (APPEND pkg_info "GIT_REPOSITORY")
			list (APPEND pkg_info ${CmDaB_${optName}})
		elseif (CmDaB_${optName})
			set (CmDaB_${optName} ${CmDaB_${optName}} PARENT_SCOPE)
		endif()
	endforeach()

	if (NOT pkg_info)
		message (FATAL_ERROR "No download informations given in description of package: ${package}")
	endif()

	set (pkg_info ${pkg_info} PARENT_SCOPE)
endfunction()

function (CmDaB_include_orig module)
	list (REMOVE_ITEM CMAKE_MODULE_PATH "${CmDaB_modules_path}")
	include (${module})
endfunction()

function (CmDaB_install package)
	CmDaB_get_package_info (${package} pkg_info)

	if (CmDaB_PLATFORMS)
		foreach (platform IN ITEMS ${CmDaB_PLATFORMS})
			if (platform MATCHES "!(.*)")
				if (${CMAKE_MATCH_1})
					message (FATAL_ERROR "CmDaB requested package ${package} is limited to platforms: ${CmDaB_PLATFORMS}")
				endif()
			else()
				if (NOT ${platform})
					message (FATAL_ERROR "CmDaB requested package ${package} is limited to platforms: ${CmDaB_PLATFORMS}")
				endif()
			endif()
		endforeach()
	endif()

	FetchContent_Declare (${package}
		"${pkg_info}"
	)

	FetchContent_MakeAvailable (${package})
endfunction()

file (GLOB includes
	packages/*.cmake
)

foreach (pkg IN LISTS includes)
	include (${pkg})
endforeach()

list (PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/modules)
set (CmDaB_modules_path ${CMAKE_CURRENT_SOURCE_DIR}/modules PARENT_SCOPE)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)

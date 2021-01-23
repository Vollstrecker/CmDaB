# CmDaB
Cmake Download and Build dependencies if not found on the system

With this framework you'll be able to just download everything that is needed and not provided by the system while your usual configure
run. Everything needed it built in one step and installed all together.

In addition it assures you that you can always use the same name for the libs when linking.

To be listed here, you need to provide <libname>::Shared and <libame>::Static als aliases for your lib if it is just one that is built,
and <package_name>::COMPONENT_Shared and <package_name>::COMPONENT_Static if it's framework or similar, both in you CMakeLists.txt and
the installed package config files.

Planned features:
  - download and use the headers in the right version for an already installed lib to link against
  - react on find_* calls and install the packages if not found
  - make configurable what is to be installed
  - make configurable which packages run their tests while main run it's
  - find libraries and headers for libs that don't have a find module
  - overwrite some poorly written find modules from original cmake (till they get included upstream)
  - maybe rename tests to have a better overview from which package they are
  - maybe rename options to make clear for which package they are
  
  For usage in you project, simply copy and include CmDaB.cmake from this poject's root. It will add an option DOWNLOAD_AND_BUILD_DEPS if git is found.
  You can then do usual checks for your deps. if they are not found and the user activated this option (default to off) simply call CmDaB_install (<package_name>)
  and continue as normal.

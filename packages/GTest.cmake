CmDaB_declare(GTest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG main

  OPTIONS
    INSTALL_GTEST OFF
    BUILD_GTEST ON
    BUILD_GMOCK ON
  TEST_OPTIONS
    gtest_build_tests
    gmock_build_tests
  ALIASES
    GTest::gtest        gtest
    GTest::gtest_main   gtest_main
    GTest::gmock        gmock
    GTest::gmock_main   gmock_main
)

function(GTest_Handle_Find)
  set(_need_gtest FALSE)
  set(_need_gmock FALSE)
  set(_required_targets)

  if(GTest_FIND_COMPONENTS)
    foreach(comp IN LISTS GTest_FIND_COMPONENTS)
      if(comp STREQUAL "gtest")
        set(_need_gtest TRUE)
        list(APPEND _required_targets GTest::gtest gtest)
      elseif(comp STREQUAL "gtest_main")
        set(_need_gtest TRUE)
        list(APPEND _required_targets GTest::gtest_main gtest_main)
      elseif(comp STREQUAL "gmock")
        set(_need_gmock TRUE)
        list(APPEND _required_targets GTest::gmock gmock)
      elseif(comp STREQUAL "gmock_main")
        set(_need_gmock TRUE)
        list(APPEND _required_targets GTest::gmock_main gmock_main)
      endif()
    endforeach()
  else()
    set(_need_gtest TRUE)
    set(_need_gmock TRUE)

    list(APPEND _required_targets
      GTest::gtest        gtest
      GTest::gtest_main   gtest_main
      GTest::gmock        gmock
      GTest::gmock_main   gmock_main
    )
  endif()

  if(MSVC)
    string(CONCAT _flags
      " ${CMAKE_C_FLAGS}"
      " ${CMAKE_C_FLAGS_DEBUG}"
      " ${CMAKE_C_FLAGS_RELEASE}"
      " ${CMAKE_CXX_FLAGS}"
      " ${CMAKE_CXX_FLAGS_DEBUG}"
      " ${CMAKE_CXX_FLAGS_RELEASE}")

    if(_flags MATCHES "/MD")
      set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    endif()
  endif()

  if(NOT CmDaB_Always_Download)

    CmDaB_Remove_Prefix()

    if(GTest_FIND_COMPONENTS)
      find_package(GTest QUIET COMPONENTS ${GTest_FIND_COMPONENTS})
    else()
      find_package(GTest QUIET)
    endif()

    CmDaB_Add_Prefix()

    set(_ok TRUE)
    foreach(t IN LISTS _required_targets)
      if(NOT TARGET ${t})
        set(_ok FALSE)
        break()
      endif()
    endforeach()

    if(_ok)
      return()
    endif()
  endif()

  get_property(_opts GLOBAL PROPERTY CmDaB_GTest_OPTIONS)

  if(_opts)
    foreach(_k _v IN LISTS _opts)
      if(NOT DEFINED ${_k})
        set(${_k} ${_v} CACHE BOOL "")
      endif()
    endforeach()
  endif()

  set(BUILD_GTEST ${_need_gtest} CACHE BOOL "")
  set(BUILD_GMOCK ${_need_gmock} CACHE BOOL "")

  get_property(_tests GLOBAL PROPERTY CmDaB_GTest_TEST_OPTIONS)

  foreach(_opt IN LISTS _tests)
    set(${_opt} ${CmDaB_Build_Tests} CACHE BOOL "")
  endforeach()

  FetchContent_MakeAvailable(GTest)

  get_property(_aliases GLOBAL PROPERTY CmDaB_GTest_ALIASES)

  if(_aliases)
    foreach(_alias _target IN LISTS _aliases)
      if(NOT TARGET ${_alias} AND TARGET ${_target})
        add_library(${_alias} ALIAS ${_target})
      endif()
    endforeach()
  endif()

endfunction()

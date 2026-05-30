CmDaB_declare (
  PTHREADS4W
  GIT_REPOSITORY https://github.com/Vollstrecker/pthreads4w.git
  PLATFORMS MSVC
  GIT_TAG master
)

function(PTHREADS4W_Handle_Find)
  set(_need_C FALSE)
  set(_need_CE FALSE)
  set(_need_SE FALSE)
  set(_need_SHARED FALSE)
  set(_need_STATIC FALSE)
  set(_required_targets)

  if(PTHREADS4W_FIND_COMPONENTS)
    foreach(comp IN LISTS PTHREADS4W_FIND_COMPONENTS)
      if(comp STREQUAL "Shared")
        set(_need_C TRUE)
        set(_need_SHARED TRUE)
        list(APPEND _required_targets Threads::Shared)
      elseif(comp STREQUAL "Static")
        set(_need_C TRUE)
        set(_need_STATIC TRUE)
        list(APPEND _required_targets Threads::Static)
      elseif(comp STREQUAL "CEShared")
        set(_need_CE TRUE)
        set(_need_SHARED TRUE)
        list(APPEND _required_targets Threads::CEShared)
      elseif(comp STREQUAL "CEStatic")
        set(_need_CE TRUE)
        set(_need_STATIC TRUE)
        list(APPEND _required_targets Threads::SEStatic)
      elseif(comp STREQUAL "SEShared")
        set(_need_SE TRUE)
        set(_need_SHARED TRUE)
        list(APPEND _required_targets Threads::SEShared)
      elseif(comp STREQUAL "SEStatic")
        set(_need_SE TRUE)
        set(_need_STATIC TRUE)
        list(APPEND _required_targets Threads::SEStatic)
      endif()
    endforeach()
  else()
    set(_need_C TRUE)
    set(_need_CE TRUE)
    set(_need_SE TRUE)
    set(_need_SHARED TRUE)
    set(_need_STATIC TRUE)

    list(APPEND _required_targets
      Threads::Shared
      Threads::Static
      Threads::CEShared
      Threads::CEStatic
      Threads::SEShared
      Threads::SEStatic
    )
  endif()

  if(NOT CmDaB_Always_Download)
    CmDaB_Remove_Prefix()

    if(PTHREADS3W_FIND_COMPONENTS)
      find_package(PTHREADS4W QUIET COMPONENTS ${PTHREADS4W_FIND_COMPONENTS})
    else()
      find_package(PTHREADS4W QUIET)
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

  set(PTHREADS4W_BUILD_C ${_need_C} CACHE BOOL "")
  set(PTHREADS4W_BUILD_CE ${_need_CE} CACHE BOOL "")
  set(PTHREADS4W_BUILD_SE ${_need_SE} CACHE BOOL "")
  set(PTHREADS4W_BUILD_SHARED ${_need_SHARED} CACHE BOOL "")
  set(PTHREADS4W_BUILD_STATIC ${_need_STATIC} CACHE BOOL "")
  set(PTHREADS4W_BUILD_TESTING ${CmDaB_Build_Tests} CACHE BOOL "")

  FetchContent_MakeAvailable(PTHREADS4W)
endfunction()

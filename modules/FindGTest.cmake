message (AUTHOR_WARNING "You shouldn't use FindGTest anymore. They ship a config that provides gtest and gmock for you.")

if (NOT GTest_DIR)
	find_package (GTest CONFIG)
endif()

if (NOT GTest_FOUND AND NOT GTest_DIR STREQUAL "CmDaB_BUILD")
	if (GTest_DIR STREQUAL "CmDaB_BUILD")
		CmDaB_install (googletest)
	else()
		message (STATUS "Downloading googletest...")
		CmDaB_install (googletest)
		message (STATUS "Downloading googletest...Done")

		set (GTest_DIR "CmDaB_BUILD"
			CACHE
			STRING
			"The directory containing a CMake configuration file for PTHREADS4W."
			FORCE
		)
	endif()

	set (GTest_FOUND TRUE)
	include (GoogleTest)
endif()

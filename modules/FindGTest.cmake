message (AUTHOR_WARNING "You shouldnt' use FindGTest anymore. They ship a config that provides gtest and gmock for you.")

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

	add_library (GTest::gmock ALIAS gmock)
	add_library (GTest::gmock_main ALIAS gmock_main)
	add_library (GTest::gtest ALIAS gtest)
	add_library (GTest::gtest_main ALIAS gtest_main)
	set (GTest_FOUND TRUE)
	include (GoogleTest)
endif()

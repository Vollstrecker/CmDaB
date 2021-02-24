CmDaB_include_orig (FindGTest)

if (GTEST_FOUND)
	if (CMAKE_VERSION VERSION_LESS 3.20)
		if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
			add_library (GTest::gtest ALIAS GTest::GTest)
		else ()
			# The following two blocks replicate the original FindThreads
			add_library (GTest::gtest INTERFACE IMPORTED)
			get_target_property (gtest_includes GTest::GTest INTERFACE_INCLUDE_DIRECTORIES)
			get_target_property (gtest_location GTest::GTest INTERFACE_LINK_LIBRARIES)

			set_target_properties(GTest::gtest PROPERTIES
				INTERFACE_INCLUDE_DIRECTORIES ${gtest_includes}
				INTERFACE_LINK_LIBRARIES ${gtest_location}
			)
		endif()
	endif()
else ()
	CmDaB_install (googletest)
	set (GTEST_FOUND TRUE)

	if (GTEST_NEEDS_GMOCK)
		add_library (GTest::gtest ALIAS gmock)
	else()
		add_library (GTest::gtest ALIAS gtest)
	endif()
endif()

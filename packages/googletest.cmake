CmDaB_declare (
	googletest
	GIT_REPOSITORY https://github.com/google/googletest.git
	GIT_TAG main
	TESTS_ENABLE gtest_build_tests gmock_build_tests
	GENERIC_OPTIONS_FALSE INSTALL_GTEST
	ALIASES GTest::gmock gmock
			GTest::gmock_main gmock_main
			GTest::gtest gtest
			GTest::gtest_main gtest_main
)

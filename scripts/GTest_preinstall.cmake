if (MSVC)
	if (${CMAKE_CXX_FLAGS_RELEASE} MATCHES "MD" AND NOT DEFINED gtest_force_shared_crt)
		set (gtest_force_shared_crt ON
			CACHE
			BOOL
			"PRESEEDED BY CmDaB"
			FORCE
		)
	endif()
endif()

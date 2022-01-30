if (NOT WIN32)
	CmDaB_include_orig (FindThreads)

	if (CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
		add_library (Threads::Shared ALIAS Threads::Threads)
		add_library (Threads::Static ALIAS Threads::Threads)
	else ()
		# The following two blocks replicate the original FindThreads
		add_library (Threads::Shared INTERFACE IMPORTED)
		add_library (Threads::Static INTERFACE IMPORTED)

		if (THREADS_HAVE_PTHREAD_ARG)
			set_property (TARGET Threads::Shared PROPERTY
				INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CUDA>:SHELL:-Xcompiler -pthread>"
											"$<$<NOT:$<COMPILE_LANGUAGE:CUDA>>:-pthread>"
			)

			set_property (TARGET Threads::Static PROPERTY
				INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CUDA>:SHELL:-Xcompiler -pthread>"
											"$<$<NOT:$<COMPILE_LANGUAGE:CUDA>>:-pthread>"
			)
		endif()

		if (CMAKE_THREAD_LIBS_INIT)
			get_target_property (thread_location Threads::Threads INTERFACE_LINK_LIBRARIES)

			set_target_properties(Threads::Shared PROPERTIES
				INTERFACE_LINK_LIBRARIES ${thread_location}
			)

			set_target_properties(Threads::Static PROPERTIES
				INTERFACE_LINK_LIBRARIES ${thread_location}
			)
		endif()
	endif()
else()
	if (PTHREADS4W_DIR STREQUAL "CmDaB_BUILD")
		CmDaB_install (PTHREADS4W)
	elseif (NOT PTHREADS4W_DIR)
		find_package (PTHREADS4W CONFIG)

		if (NOT PTHREADS4W_DIR)
			CmDaB_install (PTHREADS4W)

			set (PTHREADS4W_DIR "CmDaB_BUILD"
				CACHE
				STRING
				"The directory containing a CMake configuration file for PTHREADS4W."
				FORCE
			)
		endif()
	endif()
endif()

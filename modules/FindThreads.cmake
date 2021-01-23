if (NOT WIN32)
	CmDaB_include_orig (FindThreads)
	add_library (Threads::Shared ALIAS Threads::Threads)
	add_library (Threads::Static ALIAS Threads::Threads)
else()
	find_package (PTHREADS4W CONFIG)

	if (NOT PTHREADS4W_DIR)
		CmDaB_install (pthreads4w)
	endif()
endif()
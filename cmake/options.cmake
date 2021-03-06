function (CmDaB_Handle_Options package)
	if (NOT CmDaB_${package}_handled)
	# Package is requested first time
	# If overall tests are enabled, enable all enable-tests and disable all disable-tests
	# If overall tests are disabled, disable all enable-tests and enable all disable-tests
	# And Initialize The generic options
		if (CmDaB_${package}_TESTS_ENABLE)
			foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_ENABLE})
				if (CmDaB_Build_Tests)
					CmDaB_Set_Option (${opt} ON)
				else()
					CmDaB_Set_Option (${opt} OFF)
				endif()
			endforeach()
		endif()

		if (CmDaB_${package}_TESTS_DISABLE)
			foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_DISABLE})
				if (CmDaB_Build_Tests)
					CmDaB_Set_Option (${opt} OFF)
				else()
					CmDaB_Set_Option (${opt} ON)
				endif()
			endforeach()
		endif()

		foreach (opt IN ITEMS ${CmDaB_${package}_GENERIC_OPTIONS_TRUE})
			CmDaB_Set_Option (${opt} ON)
		endforeach()

		unset (opt)

		foreach (opt IN ITEMS ${CmDaB_${package}_GENERIC_OPTIONS_FALSE})
			CmDaB_Set_Option (${opt} OFF)
		endforeach()

		unset (opt)
	elseif (${CmDaB_Build_Tests_Old_State_CHANGED})
	# State of overall tests has changed, update all options accordingly.
		if (CmDaB_Build_Tests)
			if (CmDaB_${package}_TESTS_ENABLE)
				foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_ENABLE})
					CmDaB_Update_Option (${opt} ON)
				endforeach()
			endif()

			if (CmDaB_${package}_TESTS_DISABLE)
				foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_DISABLE})
					CmDaB_Update_Option (${opt} OFF)
				endforeach()
			endif()
		else()
			if (CmDaB_${package}_TESTS_ENABLE)
				foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_ENABLE})
					CmDaB_Update_Option (${opt} OFF)
				endforeach()
			endif()

			if (CmDaB_${package}_TESTS_DISABLE)
				foreach (opt IN ITEMS ${CmDaB_${package}_TESTS_DISABLE})
					CmDaB_Update_Option (${opt} ON)
				endforeach()
			endif()
		endif()
	else()
	# Overall state is unchanged and options have been set previously.
	# Check all options if they have changed.
		if (CmDaB_${package}_TESTS_ENABLE OR CmDaB_${package}_TESTS_DISABLE)
			foreach (opt IN ITEMS ${CmDaB_${package}_GENERIC_OPTIONS_FALSE} ${CmDaB_${package}_GENERIC_OPTIONS_TRUE} ${CmDaB_${package}_TESTS_DISABLE} ${CmDaB_${package}_TESTS_ENABLE})
				if (NOT ${CmDaB_${package}_${opt}} STREQUAL ${CmDaB_${package}_${opt}_Old_State})
					CmDaB_Update_Option (${opt} ${CmDaB_${package}_${opt}})
				elseif (NOT ${${opt}} STREQUAL ${${opt}_Old_State})
					CmDaB_Update_Option (${opt} ${${opt}})
				endif()
			endforeach()
		endif()
	endif()

	unset (opt)

	set (CmDaB_${package}_handled TRUE
		CACHE INTERNAL
		"To remeber that option for ${package} have been created"
		FORCE
	)
endfunction()

function (CmDaB_Set_Option optName value)
	option (CmDaB_${package}_${optName} "Mirror of ${optName}" ${value})

	set (CmDaB_${package}_${optName}_Old_State ${CmDaB_${package}_${optName}}
		CACHE INTERNAL
		"Old State to see what has changed"
		FORCE
	)

	if (NOT ${opt} STREQUAL "BUILD_TESTING")
		option (${optName} "CmDaB_Preseed" ${CmDaB__${package}_${optName}})

		set (${optName}_Old_State ${CmDaB_${package}_${optName}}
			CACHE INTERNAL
			"Old State to see what has changed"
			FORCE
		)
	endif()
endfunction()

function (CmDaB_Update_Option optName value)
	get_property (helpstring CACHE CmDaB_${package}_${optName}
		PROPERTY HELPSTRING
	)

	set (CmDaB_${package}_${optName} ${value}
		CACHE BOOL
		${helpstring}
		FORCE
	)

	unset (helpstring)

	get_property (helpstring CACHE ${optName}
		PROPERTY HELPSTRING
	)

	set (${optName} ${value}
		CACHE BOOL
		${helpstring}
		FORCE
	)

	unset (helpstring)

	set (CmDaB_${package}_${optName}_Old_State ${CmDaB_${package}_${optName}}
		CACHE INTERNAL
		"Old State to see what has changed"
		FORCE
	)

	set (${optName}_Old_State ${CmDaB_${package}_${optName}}
		CACHE INTERNAL
		"Old State to see what has changed"
		FORCE
	)
endfunction()

function (option)
	list (GET ARGN "0" opt)
	list (GET ARGN "1" helpstring)

	get_property (old_helpstring CACHE ${opt}
		PROPERTY HELPSTRING
	)

	if (old_helpstring STREQUAL "CmDaB_Preseed" AND NOT helpstring STREQUAL "ON" AND NOT helpstring STREQUAL "OFF")
		set_property (CACHE ${opt}
			PROPERTY HELPSTRING ${helpstring}
		)
	else()
		_option (${ARGN})
	endif()
endfunction()

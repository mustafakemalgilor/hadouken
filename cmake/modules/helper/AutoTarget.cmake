#!/usr/bin/env cmake

# ______________________________________________________
# Contains helper functions to invoke common git commands in CMake.
# 
# @file 	AutoTarget.cmake
# @author 	Mustafa Kemal GILOR <mgilor@nettsi.com>
# @date 	14.02.2020
# 
# Copyright (c) Nettsi Informatics Technology Inc. 
# All rights reserved. Licensed under the Apache 2.0 License. 
# See LICENSE in the project root for license information.
# 
# SPDX-License-Identifier:	Apache 2.0
# ______________________________________________________


# Creates a target name. If no name is specified,
# then project name will be the name of the target. 
function(make_target_name)
    cmake_parse_arguments(ARGS "" "" "PREFIX;NAME;SUFFIX;" ${ARGN})
    # By default, use project's name as target name.
    set(PREFERRED_NAME ${PROJECT_NAME})
    # If user specified a name, use it.
    if(ARGS_NAME)
        set(PREFERRED_NAME ${ARGS_NAME})
    endif()
    # Create target name
    set(TARGET_NAME ${ARGS_PREFIX}${PREFERRED_NAME}${ARGS_SUFFIX} PARENT_SCOPE)
endfunction()


function(add_project_include_directory)
    cmake_parse_arguments(ARGS,  "" "TARGET_NAME;TYPE;" "" ${ARGN})

    if(NOT DEFINED TARGET_NAME)
        message(FATAL_ERROR "add_project_include_directory() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "add_project_include_directory() requires TYPE parameter.")
    endif()

    if(${ARGS_TYPE} STREQUAL "INTERFACE")
        target_include_directories(${TARGET_NAME} INTERFACE ${PROJECT_SOURCE_DIR}/include/)
    else()
        target_include_directories(${TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/include/)
    endif()
endfunction()

# Add options passed as arguments to given target.
function(add_target_options)
    cmake_parse_arguments(ARGS "" "TARGET_NAME;TYPE;SUFFIX;PREFIX;NAME;PARTOF;" "LINK;COMPILE_OPTIONS;COMPILE_DEFINITIONS;DEPENDS;INCLUDES;SOURCES;HEADERS;SYMBOL_VISIBILITY;" ${ARGN})

    if(NOT DEFINED ARGS_TARGET_NAME)
        message(FATAL_ERROR "add_target_options() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "add_target_options() requires TYPE parameter.")
    endif()

    if(${ARGS_TYPE} STREQUAL "INTERFACE")
        if(DEFINED ARGS_INCLUDES)
            target_include_directories(${TARGET_NAME} INTERFACE ${ARGS_INCLUDES})
        endif()
        if(DEFINED ARGS_LINK)
            target_link_libraries(${TARGET_NAME} INTERFACE ${ARGS_LINK})
        endif()

        if(DEFINED ARGS_COMPILE_OPTIONS)
            target_compile_options(${TARGET_NAME} INTERFACE ${ARGS_COMPILE_OPTIONS})
        endif()

        if(DEFINED ARGS_SYMBOL_VISIBILITY)
            target_compile_options(${TARGET_NAME} INTERFACE -fvisibility=${ARGS_SYMBOL_VISIBILITY})
        endif()
    else()

        if(ARGS_INCLUDES)
            target_include_directories(${TARGET_NAME} PUBLIC ${ARGS_INCLUDES})
        endif()

        if(ARGS_LINK)
            target_link_libraries(${TARGET_NAME} PRIVATE ${ARGS_LINK})
        endif()

        if(ARGS_COMPILE_OPTIONS)
            target_compile_options(${TARGET_NAME} PRIVATE ${ARGS_COMPILE_OPTIONS})
        endif()
        
        if(ARGS_SYMBOL_VISIBILITY)
            target_compile_options(${TARGET_NAME} PRIVATE -fvisibility=${ARGS_SYMBOL_VISIBILITY})
        endif()
    endif()

    if(ARGS_COMPILE_DEFINITIONS)
        target_compile_definitions(${TARGET_NAME} PRIVATE ${ARGS_COMPILE_DEFINITIONS})
    endif()

    if(ARGS_DEPENDS)
        add_dependencies(${TARGET_NAME} ${ARGS_DEPENDS})
    endif()

    # We allow created targets to be a part of a bigger meta-target.
    if(ARGS_PARTOF) 
        add_dependencies(${ARGS_PARTOF} ${TARGET_NAME})
    endif()

endfunction()

function(setup_coverage_targets)
    cmake_parse_arguments(ARGS "" "TARGET_NAME;TYPE;" "LINK;" ${ARGN})
    if(NOT DEFINED ARGS_TARGET_NAME)
        message(FATAL_ERROR "setup_coverage_targets() requires TARGET_NAME parameter.")
    endif()

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "setup_coverage_targets() requires TYPE parameter.")
    endif()

    if(NOT ${ARGS_TYPE} STREQUAL "INTERFACE")
        if(${PB_PARENT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV AND GCOV)
            target_compile_options(${TARGET_NAME} PUBLIC -fprofile-arcs -ftest-coverage)
            target_link_libraries(${TARGET_NAME} PRIVATE gcov)
            
            if(${PB_PARENT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOVR AND GCOVR)
                SETUP_TARGET_FOR_COVERAGE_GCOVR_XML(NAME ${TARGET_NAME}.gcovr.xml EXECUTABLE ${TARGET_NAME} DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../)
                SETUP_TARGET_FOR_COVERAGE_GCOVR_HTML(NAME ${TARGET_NAME}.gcovr.html EXECUTABLE ${TARGET_NAME} DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../)
            endif()

            if(${PB_PARENT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LCOV AND LCOV)
                # dummy.component-x
                SETUP_TARGET_FOR_COVERAGE_LCOV(NAME ${TARGET_NAME}.lcov EXECUTABLE ${TARGET_NAME} DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../ LCOV_ARGS --directory ${CMAKE_SOURCE_DIR} --no-external)
            endif()

        endif() 
    else()
        target_compile_options(${TARGET_NAME} INTERFACE -fprofile-arcs -ftest-coverage)
    endif()
endfunction()

# This is a function which is created with aim of
# removing code repetition in cmake files.
# We're doing pretty much the same stuff on all of our library targets.
function(make_target)
    cmake_parse_arguments(ARGS "WITH_COVERAGE;EXPOSE_PROJECT_METADATA;NO_AUTO_COMPILATION_UNIT;" "TYPE;SUFFIX;PREFIX;NAME;PARTOF;PROJECT_METADATA_PREFIX;" "LINK;COMPILE_OPTIONS;COMPILE_DEFINITIONS;DEPENDS;INCLUDES;SOURCES;HEADERS;SYMBOL_VISIBILITY;" ${ARGN})

    if(NOT DEFINED ARGS_TYPE)
        message(FATAL_ERROR "make_target() requires TYPE parameter.")
    endif()

    # Create a name for the target
    make_target_name(NAME ${ARGS_NAME} PREFIX ${ARGS_PREFIX} SUFFIX ${ARGS_SUFFIX})

    if(NOT ARGS_NO_AUTO_COMPILATION_UNIT)
        # Gather sources of target to be created
        file_gather_compilation_unit()
    endif()

    # Define target according to type
    if(${ARGS_TYPE} STREQUAL "EXECUTABLE")
        add_executable(${TARGET_NAME} ${COMPILATION_UNIT} ${ARGS_SOURCES})
    elseif(${ARGS_TYPE} STREQUAL "INTERFACE")
        add_library(${TARGET_NAME} INTERFACE)
    elseif(${ARGS_TYPE} STREQUAL "SHARED")
        add_library(${TARGET_NAME} SHARED ${COMPILATION_UNIT} ${ARGS_SOURCES})
    elseif(${ARGS_TYPE} STREQUAL "STATIC")
        add_library(${TARGET_NAME} STATIC ${COMPILATION_UNIT} ${ARGS_SOURCES})
    elseif(${ARGS_TYPE} STREQUAL "UNIT_TEST")
        add_executable(${TARGET_NAME} ${COMPILATION_UNIT} ${ARGS_SOURCES})
        target_link_libraries(${TARGET_NAME} PRIVATE ${PB_PARENT_PROJECT_NAME}.test)
    elseif(${ARGS_TYPE} STREQUAL "BENCHMARK")
        add_executable(${TARGET_NAME} ${COMPILATION_UNIT} ${ARGS_SOURCES})
        target_link_libraries(${TARGET_NAME} PRIVATE ${PB_PARENT_PROJECT_NAME}.benchmark)
    endif()

    # Add project's include directory to target's include directories
    add_project_include_directory(
        TARGET_NAME ${TARGET_NAME}
        TYPE ${ARGS_TYPE}
    )

    # Add othet target options
    add_target_options(
        TARGET_NAME ${TARGET_NAME}
        TYPE ${ARGS_TYPE}
        LINK ${ARGS_LINK}
        COMPILE_OPTIONS ${ARGS_COMPILE_OPTIONS}
        COMPILE_DEFINITIONS ${ARGS_COMPILE_DEFINITIONS}
        DEPENDS ${ARGS_DEPENDS}
        PARTOF ${ARGS_PARTOF}
        SYMBOL_VISIBILITY ${ARGS_SYMBOL_VISIBILITY}
    )


    # Add coverage option if set
    if(ARGS_WITH_COVERAGE)    
        setup_coverage_targets(TARGET_NAME ${TARGET_NAME} TYPE ${ARGS_TYPE} LINK ${ARGS_LINK})
    endif()

    # Expose project metadata
    if(ARGS_EXPOSE_PROJECT_METADATA)
        if(NOT ${ARGS_TYPE} STREQUAL "INTERFACE")
            # Project metadata exposure
            project_metadata_exposure(
                TARGET_NAME ${TARGET_NAME}
                PREFIX ${ARGS_PROJECT_METADATA_PREFIX}
            )
        else()
            message(WARNING "EXPOSE_PROJECT_METADATA cannot be used with INTERFACE type targets.")
        endif()
    endif()

    # Add format target (if clang-format is available)
    if(CLANG_FORMAT)
        add_custom_target(
            ${TARGET_NAME}.format
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            COMMAND ${CLANG_FORMAT} -i -style=file ${COMPILATION_UNIT}
            COMMENT "Running `clang-format` on compilation unit of  `${TARGET_NAME}`"
        )
    endif() 

    # Interface targets are excluded from tidy.
    if(NOT ${ARGS_TYPE} STREQUAL "INTERFACE")
        if(CMAKE_CXX_CLANG_TIDY)
        
            # We need to gather target_link_libraries list and iterate through them.
            # For the ones which are indeed cmake targets, we need to obtain their include directories
            # and then pass them to clang-tidy.
            # Freaking tedious!

            set(CT_INCLUDE_DIRECTORIES "")
            get_target_property(CT_LINK_LIBRARIES ${TARGET_NAME} LINK_LIBRARIES)
            
            foreach(CT_LL IN LISTS CT_LINK_LIBRARIES)
                if(TARGET ${CT_LL})
                    # Get public and interface include directories of the target
                    get_target_property(CT_LL_INCLUDE_DIRECTORIES ${CT_LL} INTERFACE_INCLUDE_DIRECTORIES)
                    list(APPEND CT_INCLUDE_DIRECTORIES "-I${CT_LL_INCLUDE_DIRECTORIES}")
                endif()
            endforeach()

            # Add tidy target (if clang-tidy is available)
            add_custom_target(
                ${TARGET_NAME}.tidy
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                COMMAND ${CMAKE_CXX_CLANG_TIDY} ${COMPILATION_UNIT} -- -std=c++${CMAKE_CXX_STANDARD} ${CT_INCLUDE_DIRECTORIES}
                COMMENT "Running `clang-tidy` on compilation unit of `${TARGET_NAME}`"
            )
        endif()


        # Include what you use integration
        if(CMAKE_CXX_INCLUDE_WHAT_YOU_USE)
            # This is not required as top level CMAKE_CXX_INCLUDE_WHAT_YOU_USE implies the desired behaviour.
            #set_property(TARGET ${TARGET_NAME} PROPERTY CXX_INCLUDE_WHAT_YOU_USE ${CMAKE_CXX_INCLUDE_WHAT_YOU_USE})
        endif()
       
    endif()

    # post options
    if(${ARGS_TYPE} STREQUAL "UNIT_TEST")
        add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})
        gtest_discover_tests(${TARGET_NAME})
    endif()

endfunction()

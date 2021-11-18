# Copyright (c) 2012 - 2017, Lars Bilke
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# CHANGES:
#
# 2012-01-31, Lars Bilke
# - Enable Code Coverage
#
# 2013-09-17, Joakim Söderberg
# - Added support for Clang.
# - Some additional usage instructions.
#
#!/usr/bin/env cmake

# 2016-02-03, Lars Bilke
# - Refactored functions to use named parameters
#
# 2017-06-02, Lars Bilke
# - Merged with modified version from github.com/ufz/ogs
#
#
# USAGE:
#
# 1. Copy this file into your cmake modules path.
#
# 2. Add the following line to your CMakeLists.txt:
#      include(CodeCoverage)
#
# 3. Append necessary compiler flags:
#      APPEND_COVERAGE_COMPILER_FLAGS()
#
# 3.a (OPTIONAL) Set appropriate optimization flags, e.g. -O0, -O1 or -Og
#
# 4. If you need to exclude additional directories from the report, specify them
#    using the COVERAGE_LCOV_EXCLUDES variable before calling SETUP_TARGET_FOR_COVERAGE_LCOV.
#    Example:
#      set(COVERAGE_LCOV_EXCLUDES 'dir1/*' 'dir2/*')
#
# 5. Use the functions described below to create a custom make target which
#    runs your test executable and produces a code coverage report.
#
# 6. Build a Debug build:
#      cmake -DCMAKE_BUILD_TYPE=Debug ..
#      make
#      make my_coverage_target
#

if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV OR ${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LLVM_COV)

    include(CMakeParseArguments)

    # Check prereqs
    find_program(LCOV_PATH  NAMES lcov lcov.bat lcov.exe lcov.perl)
    find_program(GENHTML_PATH NAMES genhtml genhtml.perl genhtml.bat)
    find_program(GCOVR_PATH gcovr PATHS ${CMAKE_SOURCE_DIR}/scripts/test)
    find_package(Python COMPONENTS Interpreter)

    if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV AND ${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LLVM_COV)
        message(FATAL_ERROR "Due to compatibility issues you cannot use both of gcov and llvm-cov together in project! Aborting...")
    endif()

    # if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV)
    #     find_program(GCOV_PATH gcov)
    #     if(NOT GCOV_PATH AND ${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV)
    #         message(FATAL_ERROR "gcov not found! Aborting...")
    #     endif() # NOT GCOV_PATH
    # endif() # ${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GCOV
    #
    # if(${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LLVM_COV)
    #     find_program(LLVM_COV_PATH llvm-cov)
    #     if(NOT LLVM_COV_PATH)
    #         message(FATAL_ERROR "llvm-cov not found! Aborting...")
    #     endif() # NOT LLVM_COV_PATH
    # endif() # ${HDK_ROOT_PROJECT_NAME_UPPER}_TOOLCONF_USE_LLVM_COV

    # message(STATUS ${CMAKE_CXX_COMPILER_ID})
    # if("${CMAKE_CXX_COMPILER_ID}" MATCHES "(Apple)?[Cc]lang")
    #     if("${CMAKE_CXX_COMPILER_VERSION}" VERSION_LESS 3)
    #         message(FATAL_ERROR "Clang version must be 3.0.0 or greater! Aborting...")
    #     endif()
    # elseif(NOT "${CMAKE_CXX_COMPILER_ID}" MATCHES "[gG][nN][uU]")
    #     message(FATAL_ERROR "Compiler is not GNU gcc! Aborting...")
    # endif()

    set(COVERAGE_COMPILER_FLAGS "-g --coverage -fprofile-arcs -ftest-coverage"
        CACHE INTERNAL "")

    set(CMAKE_CXX_FLAGS_COVERAGE
        ${COVERAGE_COMPILER_FLAGS}
        CACHE STRING "Flags used by the C++ compiler during coverage builds."
        FORCE )
    set(CMAKE_C_FLAGS_COVERAGE
        ${COVERAGE_COMPILER_FLAGS}
        CACHE STRING "Flags used by the C compiler during coverage builds."
        FORCE )
    set(CMAKE_EXE_LINKER_FLAGS_COVERAGE
        ""
        CACHE STRING "Flags used for linking binaries during coverage builds."
        FORCE )
    set(CMAKE_SHARED_LINKER_FLAGS_COVERAGE
        ""
        CACHE STRING "Flags used by the shared libraries linker during coverage builds."
        FORCE )
    mark_as_advanced(
        CMAKE_CXX_FLAGS_COVERAGE
        CMAKE_C_FLAGS_COVERAGE
        CMAKE_EXE_LINKER_FLAGS_COVERAGE
        CMAKE_SHARED_LINKER_FLAGS_COVERAGE )

    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        message(STATUS "Code coverage results with an optimised (non-Debug) build may be misleading")
    endif() # NOT CMAKE_BUILD_TYPE STREQUAL "Debug"

    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        link_libraries(gcov)
    else()
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
    endif()

endif()

# Defines a target for running and collection code coverage information
# Builds dependencies, runs the given executable and outputs reports.
# NOTE! The executable should always have a ZERO as exit code otherwise
# the coverage generation will not complete.
#
# SETUP_TARGET_FOR_COVERAGE_GCOVR_XML(
#     NAME ctest_coverage                    # New target name
#     EXECUTABLE ctest -j ${PROCESSOR_COUNT} # Executable in PROJECT_BINARY_DIR
#     DEPENDENCIES executable_target         # Dependencies to build first
# )
function(SETUP_TARGET_FOR_COVERAGE_GCOVR_XML)

    set(options NONE)
    set(oneValueArgs NAME FILTER_PATTERN OUTPUT_DIRECTORY WORKING_DIRECTORY)
    set(multiValueArgs EXECUTABLE EXECUTABLE_ARGS DEPENDENCIES)
    cmake_parse_arguments(Coverage "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(NOT Python_FOUND)
        message(FATAL_ERROR "python not found! Aborting...")
    endif()

    if(NOT HDK_TOOLPATH_COVERAGE_EXECUTABLE)
        message(FATAL_ERROR "coverage executable not found! Aborting...")
    endif()

    if(NOT GCOVR_PATH)
        message(FATAL_ERROR "gcovr not found! Aborting...")
    endif() # NOT GCOVR_PATH

    if(NOT Coverage_OUTPUT_DIRECTORY)
        set(Coverage_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
    endif()

    # Combine excludes to several -e arguments
    set(GCOVR_EXCLUDES "")
    foreach(EXCLUDE ${COVERAGE_GCOVR_EXCLUDES})
        string(REPLACE "*" "\\*" EXCLUDE_REPLACED ${EXCLUDE})
        list(APPEND GCOVR_EXCLUDES "-e")
        list(APPEND GCOVR_EXCLUDES "${EXCLUDE_REPLACED}")
    endforeach()

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${Coverage_OUTPUT_DIRECTORY})

    add_custom_target(${Coverage_NAME}
        # Run tests
        ${Coverage_EXECUTABLE} ${Coverage_EXECUTABLE_ARGS}
        # Create output directory
        COMMAND ${CMAKE_COMMAND} -E make_directory ${Coverage_OUTPUT_DIRECTORY}
        # Running gcovr
        COMMAND ${GCOVR_PATH} --xml
            --gcov-executable ${HDK_TOOLPATH_COVERAGE_EXECUTABLE}
            -r ${CMAKE_SOURCE_DIR} ${GCOVR_EXCLUDES}
            --object-directory=${PROJECT_BINARY_DIR}
            --filter ${Coverage_FILTER_PATTERN}
            -o ${Coverage_OUTPUT_DIRECTORY}/${Coverage_NAME}.xml
        WORKING_DIRECTORY ${Coverage_WORKING_DIRECTORY}
        DEPENDS ${Coverage_DEPENDENCIES}
        COMMENT "Running gcovr to produce Cobertura code coverage report."
    )

    # Show info where to find the report
    add_custom_command(TARGET ${Coverage_NAME} POST_BUILD
        COMMAND ;
        COMMENT "Cobertura code coverage report saved in ${Coverage_OUTPUT_DIRECTORY}/${Coverage_NAME}.xml."
    )

endfunction() # SETUP_TARGET_FOR_COVERAGE_GCOVR_XML

# Defines a target for running and collection code coverage information
# Builds dependencies, runs the given executable and outputs reports.
# NOTE! The executable should always have a ZERO as exit code otherwise
# the coverage generation will not complete.
#
# SETUP_TARGET_FOR_COVERAGE_GCOVR_HTML(
#     NAME ctest_coverage                    # New target name
#     EXECUTABLE ctest -j ${PROCESSOR_COUNT} # Executable in PROJECT_BINARY_DIR
#     DEPENDENCIES executable_target         # Dependencies to build first
# )
function(SETUP_TARGET_FOR_COVERAGE_GCOVR_HTML)

    set(options NONE)
    set(oneValueArgs NAME FILTER_PATTERN OUTPUT_DIRECTORY WORKING_DIRECTORY)
    set(multiValueArgs EXECUTABLE EXECUTABLE_ARGS DEPENDENCIES)
    cmake_parse_arguments(Coverage "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT Python_FOUND)
        message(FATAL_ERROR "python not found! Aborting...")
    endif()

    if(NOT HDK_TOOLPATH_COVERAGE_EXECUTABLE)
        message(FATAL_ERROR "coverage executable not found! Aborting...")
    endif()

    if(NOT GCOVR_PATH)
        message(FATAL_ERROR "gcovr not found! Aborting...")
    endif() # NOT GCOVR_PATH

    if(NOT Coverage_OUTPUT_DIRECTORY)
        set(Coverage_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
    endif()

    # Combine excludes to several -e arguments
    set(GCOVR_EXCLUDES "")
    foreach(EXCLUDE ${COVERAGE_GCOVR_EXCLUDES})
        string(REPLACE "*" "\\*" EXCLUDE_REPLACED ${EXCLUDE})
        list(APPEND GCOVR_EXCLUDES "-e")
        list(APPEND GCOVR_EXCLUDES "${EXCLUDE_REPLACED}")
    endforeach()

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${Coverage_OUTPUT_DIRECTORY})

    add_custom_target(${Coverage_NAME}
        # Run tests
        ${Coverage_EXECUTABLE} ${Coverage_EXECUTABLE_ARGS}
        # Create output directory
        COMMAND ${CMAKE_COMMAND} -E make_directory ${Coverage_OUTPUT_DIRECTORY}
        # Create folder
        COMMAND ${CMAKE_COMMAND} -E make_directory ${Coverage_OUTPUT_DIRECTORY}/${Coverage_NAME}

        # Running gcovr
        COMMAND ${Python_EXECUTABLE} ${GCOVR_PATH} --html --html-details --html-title ${HDK_TOOLCONF_COVERAGE_HTML_TITLE}
            --gcov-executable ${HDK_TOOLPATH_COVERAGE_EXECUTABLE}
            -r ${CMAKE_SOURCE_DIR} ${GCOVR_EXCLUDES}
            --object-directory=${PROJECT_BINARY_DIR}
            --filter ${Coverage_FILTER_PATTERN}
            -o ${Coverage_OUTPUT_DIRECTORY}/${Coverage_NAME}/index.html
        WORKING_DIRECTORY ${Coverage_WORKING_DIRECTORY}
        DEPENDS ${Coverage_DEPENDENCIES}
        COMMENT "Running gcovr to produce HTML code coverage report."
    )

    # Show info where to find the report
    add_custom_command(TARGET ${Coverage_NAME} POST_BUILD
        COMMAND ;
        COMMENT "Open ${Coverage_OUTPUT_DIRECTORY}/${Coverage_NAME}/index.html in your browser to view the coverage report."
    )

endfunction() # SETUP_TARGET_FOR_COVERAGE_GCOVR_HTML



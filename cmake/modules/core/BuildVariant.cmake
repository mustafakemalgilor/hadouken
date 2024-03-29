#!/usr/bin/env cmake

# ______________________________________________________
# Contains helper functions to invoke common git commands in CMake.
# 
# @file 	BuildVariant.cmake
# @author Mustafa Kemal GILOR <mgilor@nettsi.com>
# @date 	25.02.2020
# 
# Copyright (c) Nettsi Informatics Technology Inc. 
# All rights reserved. Licensed under the Apache 2.0 License. 
# See LICENSE in the project root for license information.
# 
# SPDX-License-Identifier:	Apache 2.0
# ______________________________________________________

include_guard(DIRECTORY)

include(CMakeDetermineCCompiler)
include(CMakeDetermineCXXCompiler)

option(${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_NO_CXX_FLAGS_SUMMARY "Enable/disable cxx flags summary"   OFF             )
option(${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_NO_DEBUG_RELEASE_WARNING "Enable/disable debug/release mode warnings"   OFF             )


function(hdk_set_build_variant)
  hdk_log_set_context("hadouken.buildvariant")
  hdk_log_status("Setting up build variant and flags")

  if(NOT CMAKE_BUILD_TYPE)
    hdk_log_status("Build variant is not explicitly specified. Assuming `RelWithDebInfo`.")
    set(CMAKE_BUILD_TYPE RelWithDebInfo PARENT_SCOPE)
  endif()

  hdk_log_status("Build variant: ${CMAKE_BUILD_TYPE}")
  hdk_log_verbose("CXX flags (debug): ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_DEBUG}")
  hdk_log_verbose("CXX flags (release): ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_RELEASE}")
  hdk_log_verbose("CXX flags (relwithdebinfo): ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_RELWITHDEBINFO}")
  hdk_log_verbose("CXX flags (minsizerel): ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_MINSIZEREL}")

  set(CMAKE_CXX_FLAGS_DEBUG ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_DEBUG})
  set(CMAKE_CXX_FLAGS_RELEASE ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_RELEASE})
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_RELWITHDEBINFO})
  set(CMAKE_CXX_FLAGS_MINSIZEREL ${${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_CXX_FLAGS_MINSIZEREL})


  if((CMAKE_CXX_COMPILER_ID MATCHES "[gG][nN][uU]") OR (CMAKE_C_COMPILER_ID MATCHES "[gG][nN][uU]"))
    hdk_log_status("Toolchain: GNU (GCC) version ${CMAKE_CXX_COMPILER_VERSION}")
    set(HADOUKEN_COMPILER GCC)
    include(core/DiagnosticFlags_GCC)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES "[cC][lL][aA][nN][gG]") OR (CMAKE_C_COMPILER_ID MATCHES "[cC][lL][aA][nN][gG]") )
    hdk_log_status("Toolchain: LLVM (Clang) version ${CMAKE_CXX_COMPILER_VERSION}")
    set(HADOUKEN_COMPILER CLANG)
    include(core/DiagnosticFlags_Clang)
  else()
    hdk_log_warn("Unable to determine toolchain")
    return()
  endif()

  set(WARN_BUT_NO_ERROR "") 
  set(EXTENDED_WARNINGS "")
  set(EXCLUDED_WARNIGS "")

  # Append 
  foreach(VER_MAJOR RANGE 0 99)
    foreach(VER_MINOR RANGE 0 99)

      if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER ${VER_MAJOR}.${VER_MINOR})

        # Warn but no error
        if(DEFINED ${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_WARN_BUT_NO_ERROR)
          hdk_log_trace("Appended ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_WARN_BUT_NO_ERROR} to WARN_BUT_NO_ERROR")
          string(CONCAT WARN_BUT_NO_ERROR ${WARN_BUT_NO_ERROR} " " ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_WARN_BUT_NO_ERROR})
        endif()

        # Extended warnings which are not included in -Wall
        if(DEFINED ${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXTENDED_WARNINGS)
          hdk_log_trace("Appended ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXTENDED_WARNINGS} to EXTENDED_WARNINGS")
          string(CONCAT EXTENDED_WARNINGS ${EXTENDED_WARNINGS} " " ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXTENDED_WARNINGS})
        endif()

        # Excluded warnings which are included in -Wall but not so much useful
        if(DEFINED ${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXCLUDED_WARNINGS)
          hdk_log_trace("Appended ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXCLUDED_WARNINGS} to EXCLUDED_WARNINGS")
          string(CONCAT EXCLUDED_WARNINGS ${EXCLUDED_WARNINGS} " " ${${HADOUKEN_COMPILER}_${VER_MAJOR}${VER_MINOR}_EXCLUDED_WARNINGS})
        endif()

      endif()
    endforeach()
  endforeach()

  string(STRIP "${WARN_BUT_NO_ERROR}" WARN_BUT_NO_ERROR)
  string(STRIP "${EXTENDED_WARNINGS}" EXTENDED_WARNINGS)
  string(STRIP "${EXCLUDED_WARNINGS}" EXCLUDED_WARNINGS)

  if((CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR (CMAKE_BUILD_TYPE MATCHES Release))
    if(NOT ${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_NO_DEBUG_RELEASE_WARNING)
      hdk_log_status("########################################################################")
      hdk_log_status("BEWARE: As this is a release build, warnings will be treated as errors.")
      hdk_log_status("########################################################################")
    endif()
    set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wpedantic ${EXTENDED_WARNINGS} -Werror ${EXCLUDED_WARNINGS} ${EXCLUDED_WERRORS}")
  else()
    if(NOT ${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_NO_DEBUG_RELEASE_WARNING)
      hdk_log_status("########################################################################")
      hdk_log_status("NOTE: In debug builds, -Werror is disabled in order to not frustate you.")
      hdk_log_status("Build your code with release variant before committing it to the remote.")
      hdk_log_status("Release build will fail on any kind of warning generated by compiler.")
      hdk_log_status("########################################################################")
    endif()
    set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wpedantic ${EXTENDED_WARNINGS} ${WARN_BUT_NO_ERROR} ${EXCLUDED_WARNINGS}")
  endif()
  if(NOT ${HDK_ROOT_PROJECT_NAME_UPPER}_HDK_NO_CXX_FLAGS_SUMMARY)
    hdk_log_status("########################################################################")
    hdk_log_status("CXX Flags")
    hdk_log_indent(2)
    hdk_log_status("(all):              ${CMAKE_CXX_FLAGS}")
    hdk_log_status("(debug):            ${CMAKE_CXX_FLAGS_DEBUG}")
    hdk_log_status("(release):          ${CMAKE_CXX_FLAGS_RELEASE}")
    hdk_log_status("(relwithdebinfo):   ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
    hdk_log_status("(minsizerel):       ${CMAKE_CXX_FLAGS_MINSIZEREL}")
    hdk_log_unindent(2)
    hdk_log_status("########################################################################")
  endif()

  set(CMAKE_CXX_FLAGS                 ${CMAKE_CXX_FLAGS}                PARENT_SCOPE)
  set(CMAKE_CXX_FLAGS_DEBUG           ${CMAKE_CXX_FLAGS_DEBUG}          PARENT_SCOPE)
  set(CMAKE_CXX_FLAGS_RELEASE         ${CMAKE_CXX_FLAGS_RELEASE}        PARENT_SCOPE)
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO  ${CMAKE_CXX_FLAGS_RELWITHDEBINFO} PARENT_SCOPE)
  set(CMAKE_CXX_FLAGS_MINSIZEREL      ${CMAKE_CXX_FLAGS_MINSIZEREL}     PARENT_SCOPE)
  set(HADOUKEN_COMPILER               ${HADOUKEN_COMPILER}              PARENT_SCOPE)
endfunction()



function (hdk_build_variant_export_to_macro)
    cmake_parse_arguments(ARGS "" "PREFIX;" "" ${ARGN})

    if(ARGS_PREFIX)
        string(TOUPPER ${ARGS_PREFIX} ARGS_PREFIX)

        # Maket it C preprocessor macro friently
        string(REGEX REPLACE "[^a-zA-Z0-9]" "_" ARGS_PREFIX ${ARGS_PREFIX})
    endif()

    if(CMAKE_BUILD_TYPE MATCHES Debug)
      add_compile_definitions(${ARGS_PREFIX}DEBUG=1)
    else()
      # Other build types are considered non-debug
      add_compile_definitions(${ARGS_PREFIX}NDEBUG=1)
    endif()
endfunction()
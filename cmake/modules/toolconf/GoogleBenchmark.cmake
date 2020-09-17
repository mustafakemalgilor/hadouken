#!/usr/bin/env cmake

# ______________________________________________________
# CMake module for locating and linking google benchmark.
# 
# @file 	GoogleTest.cmake
# @author 	Mustafa Kemal GILOR <mgilor@nettsi.com>
# @date 	28.02.2020
# 
# Copyright (c) Nettsi Informatics Technology Inc. 
# All rights reserved. Licensed under the Apache 2.0 License. 
# See LICENSE in the project root for license information.
# 
# SPDX-License-Identifier:	Apache 2.0
# ______________________________________________________

if(${PB_PARENT_PROJECT_NAME_UPPER}_TOOLCONF_USE_GOOGLE_BENCH)
    message(STATUS "[*] Configuring `googlebench`")
    
    find_package(benchmark QUIET REQUIRED)

    make_target(
        NAME ${PB_PARENT_PROJECT_NAME}.hadouken_autotargets.benchmark    
        TYPE STATIC SOURCES ${PROJECT_SOURCE_DIR}/.hadouken/cmake/modules/toolconf/GoogleBenchmark.cpp 
        LINK PUBLIC benchmark::benchmark benchmark::benchmark_main
    )
endif()
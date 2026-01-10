cmake_minimum_required(VERSION 3.19)

include(CMakeParseArguments)

function(zig_import_target)
    cmake_parse_arguments(
        ZARG # prefix of output variables
        "REQUIRED" # list of names of the boolean arguments (only defined ones will be true)
        "PATH;COMPILE_TARGET;COMPILE_CPU" # list of names of mono-valued arguments
        "STEPS;TARGETS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    find_program(ZIG_EXE "zig" REQUIRED)
    if (NOT ZARG_PATH)
        message(FATAL_ERROR "No path specified")
    endif()
    if (NOT ZARG_COMPILE_TARGET)
        set(ZARG_COMPILE_TARGET "native")
    endif()
    if (NOT ZARG_STEPS)
        message(FATAL_ERROR "no target specified")
    endif()
    if (ZARG_COMPILE_CPU)
        set(ZARG_COMPILE_CPU "-Dcpu=${ZARG_COMPILE_CPU}")
    endif()

    list(JOIN ZARG_TARGETS " " "PLAIN_TARGETS")

    foreach(ZARG_TARGET IN LISTS ZARG_STEPS)
        message(CHECK_START "Importing Zig Target ${ZARG_TARGET}")
        execute_process(
            COMMAND
                ${ZIG_EXE} build
                --build-runner "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_runner.zig"
                --step "${ZARG_TARGET}"
                ${ZARG_COMPILE_CPU}
                ${PLAIN_TARGETS}
                "-Dtarget=${ZARG_COMPILE_TARGET}"
            WORKING_DIRECTORY ${ZARG_PATH}
            OUTPUT_VARIABLE TARGET_INFO
            RESULT_VARIABLE STATUS_CODE
            #COMMAND_ECHO STDOUT
        )

        if (STATUS_CODE EQUAL 2)
            message(CHECK_FAIL "failed to find target")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        elseif (NOT STATUS_CODE EQUAL 0)
            message(CHECK_FAIL "failed to build")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()

        string(JSON TARGET_NAME GET "${TARGET_INFO}" name)
        string(JSON TARGET_KIND GET "${TARGET_INFO}" kind)
        string(JSON TARGET_LINKAGE GET "${TARGET_INFO}" linkage)
        string(JSON TARGET_PATH GET "${TARGET_INFO}" emitted_path)

        if (NOT TARGET_PATH)
            message(CHECK_FAIL "no emit path provided")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()

        cmake_path(APPEND FULL_TARGET_PATH "${ZARG_PATH}" "${TARGET_PATH}")

        if (TARGET_LINKAGE STREQUAL dynamic)
            set(LINKAGE "SHARED")
        elseif (TARGET_LINKAGE STREQUAL static)
            set(LINKAGE "STATIC")
        else()
            message(CHECK_FAIL "unknown linkage ${TARGET_LINKAGE}")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()

        if (TARGET_KIND STREQUAL exe)
            add_executable(${TARGET_NAME} IMPORTED)
        elseif (TARGET_KIND STREQUAL lib)
            add_library(${TARGET_NAME} ${LINKAGE} IMPORTED)
        else()
            message(CHECK_FAIL "unknown kind ${TARGET_KIND}")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()
        set_property(
            TARGET ${TARGET_NAME}
            PROPERTY
                IMPORTED_LOCATION "${FULL_TARGET_PATH}"
        )

        message(CHECK_PASS "${TARGET_PATH}")
    endforeach()
endfunction(zig_import_target)


cmake_minimum_required(VERSION 3.19)

include(CMakeParseArguments)

function(zig_import_targets)
    cmake_parse_arguments(
        ZARG # prefix of output variables
        "REQUIRED" # list of names of the boolean arguments (only defined ones will be true)
        "PATH;COMPILE_TARGET;COMPILE_CPU" # list of names of mono-valued arguments
        "TARGETS" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )
    message(CHECK_START "Importing zig targets")

    find_program(ZIG_EXE "zig" REQUIRED)
    if (NOT ZARG_PATH)
        message(FATAL_ERROR "No path specified")
    endif()
    if (NOT ZARG_COMPILE_TARGET)
        set(ZARG_COMPILE_TARGET "native")
    endif()
    if (ZARG_COMPILE_CPU)
        set(ZARG_COMPILE_CPU "-Dcpu=${ZARG_COMPILE_CPU}")
    endif()

    list(JOIN ZARG_TARGETS " " "PLAIN_TARGETS")

    set(BUILD_COMMAND
        ${ZIG_EXE} build
        --build-runner "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_runner.zig"
        "-Dtarget=${ZARG_COMPILE_TARGET}"
        ${ZARG_COMPILE_CPU}
        ${PLAIN_TARGETS}
    )

    execute_process(
        COMMAND ${BUILD_COMMAND} --steps
        WORKING_DIRECTORY ${ZARG_PATH}
        OUTPUT_VARIABLE TARGET_LIST
        RESULT_VARIABLE STATUS_CODE
    )

    add_custom_target(zig_build ALL
        COMMAND ${BUILD_COMMAND}
        WORKING_DIRECTORY ${ZARG_PATH}
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

    string(JSON TARGET_COUNT LENGTH "${TARGET_LIST}")
    math(EXPR TARGET_COUNT "${TARGET_COUNT} - 1")

    list(APPEND CMAKE_MESSAGE_INDENT "  ")
    foreach(TARGET_INDEX RANGE ${TARGET_COUNT})
        string(JSON TARGET_INFO GET "${TARGET_LIST}" ${TARGET_INDEX})
        string(JSON TARGET_NAME GET "${TARGET_INFO}" name)
        string(JSON TARGET_KIND GET "${TARGET_INFO}" kind)
        string(JSON TARGET_LINKAGE GET "${TARGET_INFO}" linkage)
        string(JSON TARGET_PATH GET "${TARGET_INFO}" emitted_path)

        message(CHECK_START "Importing Zig Target ${TARGET_NAME}")

        if (NOT TARGET_PATH)
            message(CHECK_FAIL "no emit path provided")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()

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
            add_executable(zig::${TARGET_NAME} IMPORTED)
        elseif (TARGET_KIND STREQUAL lib)
            add_library(zig::${TARGET_NAME} ${LINKAGE} IMPORTED)
        else()
            message(CHECK_FAIL "unknown kind ${TARGET_KIND}")
            if (ZARG_REQUIRED)
                message(SEND_ERROR)
            endif()
            return()
        endif()

        set_property(
            TARGET zig::${TARGET_NAME}
            PROPERTY
                IMPORTED_LOCATION "${TARGET_PATH}"
        )

        message(CHECK_PASS "${TARGET_PATH}")
    endforeach()
    list(POP_BACK CMAKE_MESSAGE_INDENT)

    message(CHECK_PASS "all targets imported")

endfunction(zig_import_targets)


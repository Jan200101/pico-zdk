cmake_minimum_required(VERSION 3.14)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(zig_import)
include(pico_sdk_import)

project(pico-zdk C CXX ASM)

pico_sdk_init()

zig_import_targets(
    PATH "${CMAKE_CURRENT_SOURCE_DIR}"
    COMPILE_TARGET thumb-other-eabi
    COMPILE_CPU cortex_m0plus
    REQUIRED
)

add_executable(pico_zdk
	src/main.c
)

target_link_libraries(pico_zdk PUBLIC
	pico_stdlib
	zig::example
)
target_link_options(pico_zdk PRIVATE -Wl,--print-memory-usage)

pico_enable_stdio_usb(pico_zdk 1)
pico_enable_stdio_uart(pico_zdk 1)

pico_add_extra_outputs(pico_zdk)

set_target_properties(pico_zdk PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

find_program(PICOTOOL picotool)
if (NOT PICOTOOL STREQUAL "PICOTOOL-NOTFOUND")
    add_custom_target(flash
        COMMAND ${PICOTOOL} load -v -x ${CMAKE_BINARY_DIR}/pico_zdk.elf -f
        DEPENDS pico_zdk
        USES_TERMINAL
    )
endif()

find_program(PICOCOM picocom)
if (NOT PICOCOM STREQUAL "PICOCOM-NOTFOUND")
    add_custom_target(monitor
        COMMAND ${PICOCOM} /dev/ttyACM0 -b 115200
        USES_TERMINAL
    )
endif()

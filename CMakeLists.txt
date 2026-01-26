cmake_minimum_required(VERSION 3.14)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(zig_import)
include(pico_sdk_import)

project(pico-zdk C CXX ASM)

# newlib is used to implement IO in C
set(PICO_CLIB newlib)
pico_sdk_init()

find_package(littlefs)
add_subdirectory(deps/freertos)
include_directories(deps/freertos)

if (PICO_CYW43_SUPPORTED)
    set(ZIG_NETWORKING "true")
else()
    set(ZIG_NETWORKING "false")
endif()

zig_import_targets(
    PATH "${CMAKE_CURRENT_SOURCE_DIR}"
    COMPILE_TARGET thumb-other-eabi
    COMPILE_CPU cortex_m0plus
    OPTIONS networking=${ZIG_NETWORKING}
    REQUIRED
)

add_executable(pico_zdk
    src/main.c
    src/newlib_interface.c
)
target_include_directories(pico_zdk PUBLIC src/)
target_compile_definitions(pico_zdk PRIVATE
    PICO_CYW43_SUPPORTED=$<BOOL:${PICO_CYW43_SUPPORTED}>
)
target_link_libraries(pico_zdk PUBLIC
    pico_stdlib
    hardware_flash
    hardware_sync
    littlefs
    FreeRTOS-Kernel-Heap3
    zig::example
)
if (PICO_CYW43_SUPPORTED)
    target_link_libraries(pico_zdk PUBLIC
        pico_cyw43_arch_lwip_threadsafe_background
    )
endif()
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

set(FREERTOS_KERNEL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Kernel" CACHE PATH "Path to FreeRTOS Kernel")
message(DEBUG "FreeRTOS-Kernel set to '${FREERTOS_KERNEL_PATH}'")

include(FreeRTOS_Kernel_import.cmake)


set(LITTLEFS_DIR "${PROJECT_SOURCE_DIR}/deps/littlefs")

add_library(littlefs INTERFACE)
target_sources(littlefs INTERFACE
	${LITTLEFS_DIR}/lfs.c
	${LITTLEFS_DIR}/lfs_util.c
)
target_include_directories(littlefs INTERFACE ${LITTLEFS_DIR})
# -DLFS_YES_TRACE
# -DLFS_NO_DEBUG
target_compile_options(littlefs INTERFACE -DLFS_YES_TRACE -Wno-unused-function -Wno-null-dereference)
target_link_libraries(littlefs INTERFACE pico_sync)

#include <errno.h>
#include <fcntl.h>

#include "hardware/flash.h"
#include "hardware/sync.h"
#include "pico/time.h"
#if LIB_PICO_STDIO
#include "pico/stdio.h"
#endif
#include "lfs.h"

#define STDIO_HANDLE_STDIN  0
#define STDIO_HANDLE_STDOUT 1
#define STDIO_HANDLE_STDERR 2

#define MAX_FDS 32
#define FS_SIZE (256 * 128)

#define START_FD STDIO_HANDLE_STDERR+1
static lfs_file_t* fd_list[MAX_FDS] = {NULL};

static int pico_hal_read(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, void *buffer, lfs_size_t size);
static int pico_hal_prog(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, const void* buffer, lfs_size_t size);
static int pico_hal_erase(const struct lfs_config *c, lfs_block_t block);

static lfs_t lfs;
static struct lfs_config cfg = {
    // block device operations
    .read = pico_hal_read,
    .prog = pico_hal_prog,
    .erase = pico_hal_erase,
#if LIB_PICO_MULTICORE
    .lock = pico_lock,
    .unlock = pico_unlock,
#endif
    // block device configuration
    .read_size = 1,
    .prog_size = FLASH_PAGE_SIZE,
    .block_size = FLASH_SECTOR_SIZE,
    .block_count = FS_SIZE / FLASH_SECTOR_SIZE,
    .cache_size = FLASH_SECTOR_SIZE / 4,
    .lookahead_size = 32,
    .block_cycles = 500
};

int mount(void) {
    printf("formatting\n");
    lfs_format(&lfs, &cfg);
    printf("mounting\n");
    int err = lfs_mount(&lfs, &cfg);
    if (err) {
        printf("mount error occured %i\n", err);
        return -1;
    }

    printf("mount done\n");

    return 0;
}

const char* FS_BASE = (char*)(PICO_FLASH_SIZE_BYTES - FS_SIZE);

static int pico_hal_read(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, void *buffer, lfs_size_t size)
{
    assert(block < c->block_count);
    assert(off + size <= c->block_size);
    // read flash via XIP mapped space
    memcpy(buffer, FS_BASE + XIP_NOCACHE_NOALLOC_BASE + (block * c->block_size) + off, size);
    return LFS_ERR_OK;
}

static int pico_hal_prog(const struct lfs_config *c, lfs_block_t block, lfs_off_t off, const void* buffer, lfs_size_t size)
{
    assert(block < c->block_count);
    // program with SDK
    uint32_t p = (uint32_t)FS_BASE + (block * c->block_size) + off;
    uint32_t ints = save_and_disable_interrupts();
    flash_range_program(p, buffer, size);
    restore_interrupts(ints);
    return LFS_ERR_OK;
}

static int pico_hal_erase(const struct lfs_config *c, lfs_block_t block)
{
    assert(block < c->block_count);
    // erase with SDK
    uint32_t p = (uint32_t)FS_BASE + block * c->block_size;
    uint32_t ints = save_and_disable_interrupts();
    flash_range_erase(p, c->block_size);
    restore_interrupts(ints);
    return LFS_ERR_OK;
}

static int _flags_remap(int flags) {
    return ((((flags & 3) == O_RDONLY) ? LFS_O_RDONLY : 0) |
            (((flags & 3) == O_WRONLY) ? LFS_O_WRONLY : 0) |
            (((flags & 3) == O_RDWR)   ? LFS_O_RDWR   : 0) |
            ((flags & O_CREAT)  ? LFS_O_CREAT  : 0) |
            ((flags & O_EXCL)   ? LFS_O_EXCL   : 0) |
            ((flags & O_TRUNC)  ? LFS_O_TRUNC  : 0) |
            ((flags & O_APPEND) ? LFS_O_APPEND : 0));
}

int _read(int handle, char *buffer, int length) {
#if LIB_PICO_STDIO
    // Some systems implement STDIO, OUT and ERR as the same fd
    if (handle >= STDIO_HANDLE_STDIN || handle <= STDIO_HANDLE_STDERR)
    {
        return stdio_get_until(buffer, length, at_the_end_of_time);
    }
#endif

    lfs_file_t* file = fd_list[handle];
    if (file == NULL)
    {
        errno = EBADF;
        return -1;
    }

    lfs_ssize_t ret = lfs_file_read(&lfs, file, buffer, length);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return ret;
}

int _write(int handle, char *buffer, int length) {
#if LIB_PICO_STDIO
    if (handle >= STDIO_HANDLE_STDIN || handle <= STDIO_HANDLE_STDERR)
    {
        stdio_put_string(buffer, length, false, true);
        return length;
    }
#endif

    lfs_file_t* file = fd_list[handle];
    if (file == NULL)
    {
        errno = EBADF;
        return -1;
    }

    lfs_ssize_t ret = lfs_file_read(&lfs, file, buffer, length);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return ret;
}

int _open(const char *path, int oflags, ...) {
    printf("open(%s, %i)\n", path, oflags);
    printf("WRONLY %i %i\n", oflags & O_WRONLY, O_WRONLY);
    printf("CREAT %i %i\n", oflags & O_CREAT, O_CREAT);
    printf("TRUNC %i %i\n", oflags & O_TRUNC, O_TRUNC);
    int lfs_flags = _flags_remap(oflags);

    for (int fd = START_FD; fd < MAX_FDS; ++fd)
    {
        // if valid slot
        if (fd_list[fd] == NULL)
        {
            printf("fd %i is free\n", fd);

            lfs_file_t* file = lfs_malloc(sizeof(lfs_file_t));

            int err = lfs_file_open(&lfs, file, path, lfs_flags);
            if (err)
            {
                printf("err: %i\n", err);
                lfs_free(file);

                errno = EACCES;
                return -1;
            }

            printf("fd %i assigned\n", fd);

            fd_list[fd] = file;
            return fd;
        }

        printf("fd %i not free\n", fd);
    }

	errno = ENOENT;
    return -1;
}

int _close(int fd) {
    lfs_file_t* file = fd_list[fd];
    if (file == NULL)
    {
        errno = EBADF;
        return -1;
    }

    printf("closing fd %i\n", fd);

    return 0;

    int ret = lfs_file_close(&lfs, file);
    printf("stuck?\n");

    fd_list[fd] = NULL;
    lfs_free(file);
    if (ret < 0)
    {
        printf("error _close\n");
        errno = EIO;
        return -1;
    }

    printf("exit _close\n");

    return 0;
}

int _unlink(const char *path) {
    return 0;

    int ret = lfs_remove(&lfs, path);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return 0;
}
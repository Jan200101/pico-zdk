#include <errno.h>
#include <fcntl.h>

#include "hardware/flash.h"
#include "hardware/sync.h"
#include "pico/time.h"

#include "lfs.h"

#if LIB_PICO_STDIO
#include "pico/stdio.h"
#endif

#if PICO_CYW43_SUPPORTED
#include "lwip/sockets.h"
#endif

#define STDIO_HANDLE_STDIN  0
#define STDIO_HANDLE_STDOUT 1
#define STDIO_HANDLE_STDERR 2

#define HEAP_SIZE      (128 * 1024)
#define BLOCK_SIZE      4096
#define READ_SIZE       16
#define PROG_SIZE       16
#define CACHE_SIZE      64

#define MAX_FDS 32

#define START_FD STDIO_HANDLE_STDERR+1
static lfs_file_t* fd_list[MAX_FDS] = {NULL};

static uint8_t *heap_flash = NULL;

static int heap_read(const struct lfs_config *c, lfs_block_t block, lfs_off_t offset, void *buffer, lfs_size_t size)
{
    uint8_t *addr = &heap_flash[block * c->block_size + offset];
    memcpy(buffer, addr, size);
    return 0;
}

static int heap_prog(const struct lfs_config *c, lfs_block_t block, lfs_off_t offset, const void *buffer, lfs_size_t size) {
    uint8_t *addr = &heap_flash[block * c->block_size + offset];
    memcpy(addr, buffer, size);
    return 0;
}

static int heap_erase(const struct lfs_config *c, lfs_block_t block)
{
    uint8_t *addr = &heap_flash[block * c->block_size];
    memset(addr, 0xFF, c->block_size);
    return 0;
}

static int heap_sync(const struct lfs_config *c)
{
    (void)c;
    return 0;
}

static lfs_t lfs;
static const struct lfs_config cfg = {
    .context        = &heap_flash,
    .read           = heap_read,
    .prog           = heap_prog,
    .erase          = heap_erase,
    .sync           = heap_sync,
    .read_size      = READ_SIZE,
    .prog_size      = PROG_SIZE,
    .block_size     = BLOCK_SIZE,
    .block_count    = (HEAP_SIZE / BLOCK_SIZE),
    .cache_size     = CACHE_SIZE,
    .lookahead_size = 16,
    .block_cycles   = 500,
};

int mount(void) {
    heap_flash = malloc(HEAP_SIZE);
    if (!heap_flash) return -1;
    memset(heap_flash, 0xFF, HEAP_SIZE);

    int err = lfs_format(&lfs, &cfg);
    if (err != 0) return err;

    err = lfs_mount(&lfs, &cfg);
    return err;
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
    if (handle >= STDIO_HANDLE_STDIN && handle <= STDIO_HANDLE_STDERR)
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
    if (handle >= STDIO_HANDLE_STDIN && handle <= STDIO_HANDLE_STDERR)
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

    lfs_ssize_t ret = lfs_file_write(&lfs, file, buffer, length);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return ret;
}

int _open(const char *path, int oflags, ...) {
    int lfs_flags = _flags_remap(oflags);

    for (int fd = START_FD; fd < MAX_FDS; ++fd)
    {
        // if valid slot
        if (fd_list[fd] == NULL)
        {
            lfs_file_t* file = lfs_malloc(sizeof(lfs_file_t));

            int err = lfs_file_open(&lfs, file, path, lfs_flags);
            if (err)
            {
                lfs_free(file);
                errno = EACCES;
                return -1;
            }

            fd_list[fd] = file;
            return fd;
        }
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

    int ret = lfs_file_close(&lfs, file);

    fd_list[fd] = NULL;
    lfs_free(file);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return 0;
}

int _unlink(const char *path) {
    int ret = lfs_remove(&lfs, path);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return 0;
}

off_t _lseek(int fd, off_t pos, int whence) {
    lfs_file_t* file = fd_list[fd];
    if (file == NULL)
    {
        errno = EBADF;
        return -1;
    }

    int lfs_whence = -1;
    switch (whence)
    {
        case SEEK_SET:
            lfs_whence = LFS_SEEK_SET;
            break;

        case SEEK_CUR:
            lfs_whence = LFS_SEEK_CUR;
            break;

        case SEEK_END:
            lfs_whence = LFS_SEEK_END;
            break;

        default:
            errno = EINVAL;
            return -1;
    }

    int ret = lfs_file_seek(&lfs, file, pos, whence);
    if (ret < 0)
    {
        errno = EIO;
        return -1;
    }

    return 0;
}

int socket(int domain, int type, int protocol)
{
    return lwip_socket(domain, type, protocol);
}

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
{
    return lwip_bind(sockfd, addr, addrlen);
}

int listen(int sockfd, int backlog)
{
    return lwip_listen(sockfd, backlog);
}

int accept(int sockfd, struct sockaddr* addr, socklen_t* addrlen)
{
    return lwip_accept(sockfd, addr, addrlen);
}

int connect(int sockfd, const struct sockaddr* addr, socklen_t addrlen)
{
    return lwip_connect(sockfd, addr, addrlen);
}

int setsockopt(
    int sockfd, int level, int optname,
    const void* optval,
    socklen_t optlen)
{
    return lwip_setsockopt(sockfd, level, optname, optval, optlen);
}

#include <errno.h>

#include "pico/time.h"
#if LIB_PICO_STDIO
#include "pico/stdio.h"
#endif

#define STDIO_HANDLE_STDIN  0
#define STDIO_HANDLE_STDOUT 1
#define STDIO_HANDLE_STDERR 2

int _read(int handle, char *buffer, int length) {
#if LIB_PICO_STDIO
    if (handle == STDIO_HANDLE_STDIN) {
        return stdio_get_until(buffer, length, at_the_end_of_time);
    }
#endif
    return -1;
}

int _write(int handle, char *buffer, int length) {
#if LIB_PICO_STDIO
    if (handle == STDIO_HANDLE_STDOUT || handle == STDIO_HANDLE_STDERR) {
        stdio_put_string(buffer, length, false, true);
        return length;
    }
#endif
    return -1;
}

int _open(__unused const char *fn, __unused int oflag, ...) {
	errno = ENOENT;
    return -1;
}

int _close(__unused int fd) {
	errno = EBADF;
    return -1;
}

const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const private = struct {
    extern "c" fn __errno() *c_int;
};

pub const std_options: std.Options = .{
    .page_size_min = 1 << 12,
    .page_size_max = 1 << 12,
};

pub const c = struct {
    pub const _errno = private.__errno;
    pub const E = enum(c_int) { SUCCESS = 0, PERM = 1, NOENT = 2, SRCH = 3, INTR = 4, IO = 5, NXIO = 6, @"2BIG" = 7, NOEXEC = 8, BADF = 9, CHILD = 10, AGAIN = 11, NOMEM = 12, ACCES = 13, FAULT = 14, NOTBLK = 15, BUSY = 16, EXIST = 17, XDEV = 18, NODEV = 19, NOTDIR = 20, ISDIR = 21, INVAL = 22, NFILE = 23, MFILE = 24, NOTTY = 25, TXTBSY = 26, FBIG = 27, NOSPC = 28, SPIPE = 29, ROFS = 30, MLINK = 31, PIPE = 32, RANGE = 33, NAMETOOLONG = 34, LOOP = 35, OVERFLOW = 36, OPNOTSUPP = 37, NOSYS = 38, NOTIMPL = 39, AFNOSUPPORT = 40, NOTSOCK = 41, ADDRINUSE = 42, NOTEMPTY = 43, DOM = 44, CONNREFUSED = 45, HOSTDOWN = 46, ADDRNOTAVAIL = 47, ISCONN = 48, CONNABORTED = 49, ALREADY = 50, CONNRESET = 51, DESTADDRREQ = 52, HOSTUNREACH = 53, ILSEQ = 54, MSGSIZE = 55, NETDOWN = 56, NETUNREACH = 57, NETRESET = 58, NOBUFS = 59, NOLCK = 60, NOMSG = 61, NOPROTOOPT = 62, NOTCONN = 63, SHUTDOWN = 64, TOOMANYREFS = 65, SOCKTNOSUPPORT = 66, PROTONOSUPPORT = 67, DEADLK = 68, TIMEDOUT = 69, PROTOTYPE = 70, INPROGRESS = 71, NOTHREAD = 72, PROTO = 73, NOTSUP = 74, PFNOSUPPORT = 75, DIRINTOSELF = 76, DQUOT = 77, NOTRECOVERABLE = 78, CANCELED = 79, PROMISEVIOLATION = 80, STALE = 81, SRCNOTFOUND = 82, _ };
    pub const IOV_MAX = 1024;

    pub const SEEK = struct {
        pub const SET = 0;
        pub const CUR = 1;
        pub const END = 2;
        pub const DATA = 3;
        pub const HOLE = 4;
    };

    pub const PROG = struct {
        /// page can not be accessed
        pub const NONE = 0x0;
        /// page can be read
        pub const READ = 0x1;
        /// page can be written
        pub const WRITE = 0x2;
        /// page can be executed
        pub const EXEC = 0x4;
    };

    // LittleFS defaults to 255 max
    pub const PATH_MAX = 255;

    pub const MAP = packed struct(u32) {
        TYPE: enum(u2) {
            SHARED = 0x01,
            PRIVATE = 0x02,
        },
        FIXED: bool = false,
        ANONYMOUS: bool = false,
        NORESERVE: bool = false,
        _: u27 = 0,
    };

    pub const O = packed struct(c_int) {
        ACCMODE: std.posix.ACCMODE = .RDWR,
        EXEC: bool = false,
        CREAT: bool = false,
        EXCL: bool = false,
        NOCTTY: bool = false,
        TRUNC: bool = false,
        APPEND: bool = false,
        NONBLOCK: bool = false,
        DIRECTORY: bool = false,
        NOFOLLOW: bool = false,
        CLOEXEC: bool = false,
        DIRECT: bool = false,
        SYNC: bool = false,
        _: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 14) = 0,
    };

    pub const AT = struct {
        pub const FDCWD = -2;
    };
};
pub const debug = struct {
    pub const Error = error{
        MissingDebugInfo,
        UnsupportedOperatingSystem,
        InvalidDebugInfo,
    };

    pub const SelfInfo = struct {
        allocator: Allocator,
        pub const supports_unwinding = false;

        pub const Module = struct {
            pub fn getSymbolAtAddress(_: *@This(), _: Allocator, _: usize) Error!std.debug.Symbol {
                return error.UnsupportedOperatingSystem;
            }
        };

        pub fn open(_: Allocator) !SelfInfo {
            return error.UnsupportedOperatingSystem;
        }
        pub fn getModuleForAddress(_: *SelfInfo, _: usize) Error!*Module {
            return error.MissingDebugInfo;
        }

        pub fn getModuleNameForAddress(_: *SelfInfo, _: usize) ?[]const u8 {
            return null;
        }
    };
};

pub const Thread = struct {
    pub const Futex = struct {
        pub fn wait(_: *const std.atomic.Value(u32), _: u32, _: ?u64) error{Timeout}!void {
            return;
        }

        pub fn wake(_: *const std.atomic.Value(u32), _: u32) void {
            return;
        }
    };
};

fn panic(_: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {}

export fn test_print() void {
    std.fs.File.stdout().writeAll("Hello World from Zig!\n") catch {};
}

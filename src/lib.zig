const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const CIO = @import("CIO.zig");

const private = struct {
    extern "c" fn __errno() *c_int;
};

pub const std_options: std.Options = .{
    .page_size_min = 1 << 12,
    .page_size_max = 1 << 12,
};

pub const c = struct {
    pub const _errno = private.__errno;
    pub const E = enum(c_int) {
        SUCCESS = 0,
        PERM = 1,
        NOENT = 2,
        SRCH = 3,
        INTR = 4,
        IO = 5,
        NXIO = 6,
        @"2BIG" = 7,
        NOEXEC = 8,
        BADF = 9,
        CHILD = 10,
        AGAIN = 11,
        NOMEM = 12,
        ACCES = 13,
        FAULT = 14,
        NOTBLK = 15,
        BUSY = 16,
        EXIST = 17,
        XDEV = 18,
        NODEV = 19,
        NOTDIR = 20,
        ISDIR = 21,
        INVAL = 22,
        NFILE = 23,
        MFILE = 24,
        NOTTY = 25,
        TXTBSY = 26,
        FBIG = 27,
        NOSPC = 28,
        SPIPE = 29,
        ROFS = 30,
        MLINK = 31,
        PIPE = 32,
        RANGE = 33,
        NAMETOOLONG = 34,
        LOOP = 35,
        OVERFLOW = 36,
        OPNOTSUPP = 37,
        NOSYS = 38,
        NOTIMPL = 39,
        AFNOSUPPORT = 40,
        NOTSOCK = 41,
        ADDRINUSE = 42,
        NOTEMPTY = 43,
        DOM = 44,
        CONNREFUSED = 45,
        HOSTDOWN = 46,
        ADDRNOTAVAIL = 47,
        ISCONN = 48,
        CONNABORTED = 49,
        ALREADY = 50,
        CONNRESET = 51,
        DESTADDRREQ = 52,
        HOSTUNREACH = 53,
        ILSEQ = 54,
        MSGSIZE = 55,
        NETDOWN = 56,
        NETUNREACH = 57,
        NETRESET = 58,
        NOBUFS = 59,
        NOLCK = 60,
        NOMSG = 61,
        NOPROTOOPT = 62,
        NOTCONN = 63,
        SHUTDOWN = 64,
        TOOMANYREFS = 65,
        SOCKTNOSUPPORT = 66,
        PROTONOSUPPORT = 67,
        DEADLK = 68,
        TIMEDOUT = 69,
        PROTOTYPE = 70,
        INPROGRESS = 71,
        NOTHREAD = 72,
        PROTO = 73,
        NOTSUP = 74,
        PFNOSUPPORT = 75,
        DIRINTOSELF = 76,
        DQUOT = 77,
        NOTRECOVERABLE = 78,
        CANCELED = 79,
        PROMISEVIOLATION = 80,
        STALE = 81,
        SRCNOTFOUND = 82,
        _,
    };
};

pub const debug = struct {
    pub const SelfInfo = struct {
        pub const init: @This() = .{};
        pub const can_unwind: bool = false;

        const Error = std.debug.SelfInfoError;

        pub fn getSymbol(_: *SelfInfo, _: Allocator, _: Io, _: usize) Error!std.debug.Symbol {
            return error.MissingDebugInfo;
        }

        pub fn getModuleName(_: *SelfInfo, _: Allocator, _: usize) Error![]const u8 {
            return error.MissingDebugInfo;
        }
    };
};

pub const Environ = struct {
    // We don't really have an "environment" but Io.Threaded demands it
    pub const Block = [:null]const ?[*:0]const u8;
};

// pub const Thread = struct {
//     pub const Futex = struct {
//         pub fn wait(_: *const std.atomic.Value(u32), _: u32, _: ?u64) error{Timeout}!void {
//             return;
//         }

//         pub fn wake(_: *const std.atomic.Value(u32), _: u32) void {
//             return;
//         }
//     };
// };

fn panic(_: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {}

export fn test_print() void {
    const io = CIO.io();
    std.Io.File.stdout().writeStreamingAll(io, "Hello World from Zig!\n") catch {};
}

const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const net = Io.net;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const http = std.http;
const HttpServer = http.Server;

pub const options = @import("options");

const lib = @import("lib.zig");
const CIO = @import("CIO.zig");

pub const debug = @import("debug.zig");

pub const std_options_debug_io = CIO.io();
pub const std_options_cwd = CIO.cwd;
pub const panic = std.debug.FullPanic(debug.panic);

pub fn main() !void {
    lib.test_print();
    lib.test_file("TEST_FILE");
    //lib.test_panic();

    lib.test_http_server();
}

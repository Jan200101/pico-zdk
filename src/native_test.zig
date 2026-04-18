const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const net = Io.net;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const http = std.http;
const HttpServer = http.Server;

const lib = @import("lib");

pub const std_options_debug_io = lib.CIO.io();
pub const std_options_cwd = lib.CIO.cwd;
pub const panic = std.debug.FullPanic(lib.debug.panic);

pub fn main() !void {
    lib.test_print();
    lib.test_file("TEST_FILE");
    //lib.test_panic();

    lib.test_http_server();
}

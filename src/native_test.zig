const std = @import("std");
const builtin = @import("builtin");

const lib = @import("lib");

pub const options = lib.options;

pub const debug = lib.debug;

pub const std_options_debug_io = lib.std_options_debug_io;
pub const std_options_cwd = lib.std_options_cwd;
pub const panic = lib.panic;

pub fn main() !void {
    lib.test_print();
    lib.test_file("TEST_FILE");
    //lib.test_panic();

    lib.test_http_server();
}

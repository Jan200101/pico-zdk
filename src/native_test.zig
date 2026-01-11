const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const lib = @import("lib.zig");
const CIO = @import("CIO.zig");

pub const debug = @import("debug.zig");

pub const std_options_debug_io = CIO.io();
pub const panic = std.debug.FullPanic(@import("panic.zig").panic);

pub fn main() !void {
    lib.test_print();
    lib.test_panic();
}

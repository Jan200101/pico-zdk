const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const Writer = Io.Writer;
const Allocator = std.mem.Allocator;

const CIO = @import("CIO.zig");

pub const c = @import("newlib.zig");
pub const debug = @import("debug.zig");

pub const std_options_debug_io = CIO.io();
pub const std_options_cwd = CIO.cwd;
pub const panic = std.debug.FullPanic(@import("panic.zig").panic);

pub const std_options: std.Options = .{
    .page_size_min = 1 << 12,
    .page_size_max = 1 << 12,
};

pub export fn test_print() void {
    const io = CIO.io();

    std.Io.File.stdout().writeStreamingAll(io, "Hello World from Zig stdout!\n") catch {};

    std.debug.print("Hello World from Zig debug print\n", .{});
}

pub export fn test_panic() void {
    @panic("We are testing panics");
}

pub export fn test_file() void {
    const io = CIO.io();
    const cwd = std.Io.Dir.cwd();

    const f = "NOT_REAL_FILE";
    const t = cwd.openFile(io, f, .{}) catch {
        std.debug.print("{s} could not be opened\n", .{f});
        return;
    };
    defer t.close(io);

    std.debug.print("successfully opened {s}\n", .{f});
}

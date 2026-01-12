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
pub const panic = std.debug.FullPanic(debug.panic);

pub const std_options: std.Options = .{
    .page_size_min = 256,
    .page_size_max = 256,
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

    const f = "/TEST_FILE";

    std.debug.print("trying to delete file\n", .{});
    cwd.deleteFile(io, f) catch {}; // cannot create a file if it already exists

    std.debug.print("creating file\n", .{});
    {
        const t = cwd.createFile(io, f, .{}) catch {
            std.debug.print("{s} could not be created\n", .{f});
            return;
        };
        defer t.close(io);
    }
    std.debug.print("successfully create {s}\n", .{f});

    std.debug.print("deleting file\n", .{});
    {
        cwd.deleteFile(io, f) catch {
            std.debug.print("{s} could not be deleted\n", .{f});
            return;
        };
    }
    std.debug.print("successfully deleted {s}\n", .{f});
}

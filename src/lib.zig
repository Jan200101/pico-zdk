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

    std.debug.print("Hello World from Zig debug print\n\n", .{});
}

pub export fn test_panic() void {
    @panic("test panic");
}

pub export fn test_file(path: [*:0]const u8) void {
    const io = CIO.io();
    const cwd = std.Io.Dir.cwd();

    const f: []const u8 = std.mem.span(path);

    // delete the file so we can start from scratch
    cwd.deleteFile(io, f) catch {}; // cannot create a file if it already exists

    std.debug.print("opening file prematurely\n", .{});
    blk: {
        const t = cwd.openFile(io, f, .{}) catch {
            std.debug.print("{s} could not be opened\n\n", .{f});
            break :blk;
        };
        defer t.close(io);
        std.debug.print("{s} was opened despite not existing\n\n", .{f});
        return;
    }

    std.debug.print("creating file\n", .{});
    {
        const t = cwd.createFile(io, f, .{}) catch {
            std.debug.print("{s} could not be created\n\n", .{f});
            return;
        };
        defer t.close(io);
    }
    std.debug.print("successfully create {s}\n\n", .{f});

    std.debug.print("deleting file\n", .{});
    {
        cwd.deleteFile(io, f) catch {
            std.debug.print("{s} could not be deleted\n", .{f});
            return;
        };
    }
    std.debug.print("successfully deleted {s}\n\n", .{f});

    std.debug.print("deleting file again\n", .{});
    {
        cwd.deleteFile(io, f) catch {
            std.debug.print("{s} could not be deleted\n\n", .{f});
            return;
        };
    }
    std.debug.print("successfully deleted {s}\n\n", .{f});
}

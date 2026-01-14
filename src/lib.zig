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
        const t = cwd.openFile(io, f, .{}) catch |err| {
            std.debug.print("{s} could not be opened: {t}\n\n", .{ f, err });
            break :blk;
        };
        defer t.close(io);
        std.debug.print("{s} was opened despite not existing\n\n", .{f});
        return;
    }

    std.debug.print("creating file\n", .{});
    {
        const t = cwd.createFile(io, f, .{ .read = true }) catch |err| {
            std.debug.print("{s} could not be created: {t}\n\n", .{ f, err });
            return;
        };
        defer t.close(io);
        std.debug.print("successfully create {s}\n", .{f});

        const out_data = "file test data";
        t.writeStreamingAll(io, out_data) catch |err| {
            std.debug.print("{s} could not be written to: {t}\n\n", .{ f, err });
            return;
        };
        std.debug.print("successfully written \"{s}\" to {s}\n", .{ out_data, f });

        // we gotta seek back manually
        // you should really use File.Reader which does this for you
        // however I do not care
        io.vtable.fileSeekTo(io.userdata, t, 0) catch |err| {
            std.debug.print("{s} could not seek back: {t}\n\n", .{ f, err });
            return;
        };

        var buffer: [4]u8 = @splat('A');
        const read = t.readStreaming(io, &.{&buffer}) catch |err| {
            std.debug.print("{s} could not be read from: {t}\n\n", .{ f, err });
            return;
        };
        std.debug.print("successfully read {} bytes from {s}: \"{s}\"\n\n", .{ read, f, buffer[0..read] });
    }

    std.debug.print("deleting file\n", .{});
    {
        cwd.deleteFile(io, f) catch |err| {
            std.debug.print("{s} could not be deleted: {t}\n", .{ f, err });
            return;
        };
    }
    std.debug.print("successfully deleted {s}\n\n", .{f});

    std.debug.print("deleting file again\n", .{});
    {
        cwd.deleteFile(io, f) catch |err| {
            std.debug.print("{s} could not be deleted: {t}\n\n", .{ f, err });
            return;
        };
    }
    std.debug.print("successfully deleted {s}\n\n", .{f});
}

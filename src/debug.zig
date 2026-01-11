const std = @import("std");
const debug = std.debug;
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Writer = Io.Writer;

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

pub fn printLineFromFile(io: Io, writer: *Writer, source_location: debug.SourceLocation) !void {
    _ = io;
    _ = writer;
    _ = source_location;
}

pub fn getDebugInfoAllocator() Allocator {
    return std.heap.c_allocator;
}

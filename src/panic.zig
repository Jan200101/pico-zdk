const std = @import("std");
const builtin = @import("builtin");
const debug = std.debug;

threadlocal var panic_stage: usize = 0;

pub fn panic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    @branchHint(.cold);

    switch (panic_stage) {
        0 => trace: {
            panic_stage = 1;

            const stderr = debug.lockStderr(&.{}).terminal();
            defer debug.unlockStderr();
            const writer = stderr.writer;

            writer.writeAll("min panic: ") catch break :trace;
            writer.print("{s}\n", .{msg}) catch break :trace;

            if (@errorReturnTrace()) |t| if (t.index > 0) {
                writer.writeAll("error return context:\n") catch break :trace;
                debug.writeStackTrace(t, stderr) catch break :trace;
                writer.writeAll("\nstack trace:\n") catch break :trace;
            };

            debug.writeCurrentStackTrace(.{
                .first_address = first_trace_addr orelse @returnAddress(),
                .allow_unsafe_unwind = true,
            }, stderr) catch break :trace;
        },
        1 => {
            panic_stage = 2;
            // A panic happened while trying to print a previous panic message.
            // We're still holding the mutex but that's fine as we're going to
            // call abort().
            const stderr = debug.lockStderr(&.{}).terminal();
            const writer = stderr.writer;
            writer.writeAll("aborting due to recursive panic: ") catch {};
            writer.print("{s}\n", .{msg}) catch {};
        },
        else => {}, // Panicked while printing the recursive panic message.
    }

    while (true) {}
}

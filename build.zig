const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "example",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .single_threaded = true,
        }),
    });
    b.installArtifact(lib);

    if (target.query.isNative()) {
        const exe = b.addExecutable(.{
            .name = "native_test",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/native_test.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        b.installArtifact(exe);

        const run_step = b.step("run", "run");
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
    }
}

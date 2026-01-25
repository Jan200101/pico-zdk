const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const networking = b.option(bool, "networking", "") orelse true;

    const options = b.addOptions();
    options.addOption(bool, "networking", networking);

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .single_threaded = true,
    });
    lib_mod.addOptions("options", options);

    const lib = b.addLibrary(.{
        .name = "example",
        .linkage = .static,
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    if (target.query.isNative()) {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("src/native_test.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        exe_mod.addOptions("options", options);

        const exe = b.addExecutable(.{
            .name = "native_test",
            .root_module = exe_mod,
        });
        b.installArtifact(exe);

        const run_step = b.step("run", "run");
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
    }
}

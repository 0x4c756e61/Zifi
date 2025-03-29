const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("main", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.addAnonymousImport("interface", .{
        .root_source_file = b.path("src/interface.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.addAnonymousImport("packet", .{
        .root_source_file = b.path("src/packet.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ZifiSpam",
        .root_module = module,
    });

    exe.linkLibC();
    b.installArtifact(exe);

    const check_main = b.addExecutable(.{ .name = "check", .root_module = module });

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const check = b.step("check", "Checks if main compiles");
    check.dependOn(&check_main.step);
}

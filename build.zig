const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ZigCursor",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const pg = b.dependency("pg", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // exe.root_module.addImport("pg", pg.module("pg"));

    // const httpz = b.dependency("httpz", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // exe.root_module.addImport("httpz", httpz.module("httpz"));

    exe.linkLibC();

    const stack_mod = b.createModule(.{
        .root_source_file = b.path("lib/stack.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("stack", stack_mod);

    const queue_mod = b.createModule(.{
        .root_source_file = b.path("lib/queue.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("queue", queue_mod);

    const sorts_mod = b.createModule(.{
        .root_source_file = b.path("lib/sorts.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("sorts", sorts_mod);

    const utils_mod = b.createModule(.{
        .root_source_file = b.path("lib/utils.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("utils", utils_mod);

    const string_mod = b.createModule(.{
        .root_source_file = b.path("lib/string.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("string", string_mod);
    string_mod.addImport("stack", stack_mod);

    const bench_mod = b.createModule(.{
        .root_source_file = b.path("curr/benchmark.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("benchmark", bench_mod);

    const rand_mod = b.createModule(.{
        .root_source_file = b.path("curr/rand.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("rand", rand_mod);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const version: std.SemanticVersion = .{ .major = 0, .minor = 0, .patch = 0 };
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const winmm_mod = b.addModule("winmm", .{
        .root_source_file = b.path("src/bindings/winmm.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    winmm_mod.linkSystemLibrary("winmm", .{});

    const coremidi_mod = b.addModule("coremidi", .{
        .root_source_file = b.path("src/bindings/coremidi.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    coremidi_mod.linkSystemLibrary("objc", .{});
    coremidi_mod.linkFramework("CoreFoundation", .{});
    coremidi_mod.linkFramework("CoreMIDI", .{});

    const midi_common = b.createModule(.{
        .root_source_file = b.path("src/common/common.zig"),
        .target = target,
        .optimize = optimize,
    });

    const winmm_driver = b.createModule(.{
        .root_source_file = b.path("src/drivers/winmm.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "common", .module = midi_common },
            .{ .name = "winmm", .module = winmm_mod },
        },
    });

    const coremidi_driver = b.createModule(.{
        .root_source_file = b.path("src/drivers/coremidi.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "common", .module = midi_common },
            .{ .name = "coremidi", .module = coremidi_mod },
        },
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "common", .module = midi_common },
            .{ .name = "driver", .module = switch (target.result.os.tag) {
                .windows => winmm_driver,
                .macos => coremidi_driver,
                else => {
                    std.debug.print("Target platform {t} not supported\n", .{target.result.os.tag});
                    std.process.exit(1);
                },
            } },
        },
    });

    const lib = b.addLibrary(.{
        .name = "zig_midi",
        .linkage = .static,
        .root_module = mod,
        .version = version,
    });

    const lib_step = b.step("lib", "Build the static library");
    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);

    const dynlib = b.addLibrary(.{
        .name = "zig_midi",
        .linkage = .dynamic,
        .root_module = mod,
        .version = version,
    });

    const dynlib_step = b.step("dynlib", "Build the dynamic library");
    const dynlib_install = b.addInstallArtifact(dynlib, .{ .dest_dir = .{ .override = .{ .custom = "dynlib" } } });
    dynlib_step.dependOn(&dynlib_install.step);

    const example = b.addExecutable(.{
        .name = "zig_midi_example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "zig_midi", .module = mod },
            },
        }),
    });

    const check_step = b.step("check", "Check the example");
    check_step.dependOn(&example.step);

    const build_example_step = b.step("example", "Build the example");
    const build_example = b.addInstallArtifact(example, .{});
    build_example_step.dependOn(&build_example.step);

    const run_example = b.addRunArtifact(example);
    run_example.step.dependOn(&build_example.step);

    const run_example_cmd = b.step("run", "Run the example");
    run_example_cmd.dependOn(&run_example.step);

    if (b.args) |args| {
        run_example.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

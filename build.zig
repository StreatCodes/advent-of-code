const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const challenges = [_]std.build.ExecutableOptions{
        .{
            .name = "trebuchet",
            .root_source_file = .{ .path = "src/01-trebuchet.zig" },
        },
        .{
            .name = "cube-conundrum",
            .root_source_file = .{ .path = "src/02-cube-conundrum.zig" },
        },
        .{
            .name = "gear-ratios",
            .root_source_file = .{ .path = "src/03-gear-ratios.zig" },
        },
    };

    inline for (challenges) |challenge| {
        const exe = b.addExecutable(.{
            .name = challenge.name,
            .root_source_file = challenge.root_source_file,
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step("run-" ++ challenge.name, "Run the " ++ challenge.name ++ " challenge");
        run_step.dependOn(&run_cmd.step);
    }
}

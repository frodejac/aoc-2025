const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (1..13) |day| {
        const day_str = std.fmt.comptimePrint("day{d:0>2}", .{day});
        const src_path = std.fmt.comptimePrint("src/{s}.zig", .{day_str});

        const exe = b.addExecutable(.{
            .name = day_str,
            .root_module = b.createModule(.{ .root_source_file = b.path(src_path), .target = target, .optimize = optimize }),
        });

        const install_exe = b.addInstallArtifact(exe, .{});

        const run_cmd = b.addRunArtifact(exe);

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(day_str, std.fmt.comptimePrint("Run day {d}", .{day}));
        run_step.dependOn(&install_exe.step);
        run_step.dependOn(&run_cmd.step);
    }
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("upstream", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_mod.addCSourceFiles(.{
        .root = upstream.path("."),
        .files = &[_][]const u8{
            "varintdecode.c",
            "vbyte.cc",
        },
    });
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "libvbyte",
        .root_module = lib_mod,
    });
    lib.root_module.addIncludePath(upstream.path("."));

    b.installArtifact(lib);

    const mod = b.addModule("libvbyte", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.linkLibrary(lib);

    const fuzz = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/fuzz.zig"),
            .target = target,
            .optimize = optimize,
        }),
        // Required for running fuzz tests
        // https://github.com/ziglang/zig/issues/23423
        .use_llvm = true,
    });
    fuzz.root_module.addImport("libvbyte", mod);

    const run_fuzz = b.addRunArtifact(fuzz);

    const fuzz_step = b.step("fuzz", "run fuzz tests");
    fuzz_step.dependOn(&run_fuzz.step);
}

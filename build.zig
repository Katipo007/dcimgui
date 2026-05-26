const std = @import("std");
const Build = std.Build;
const builtin = @import("builtin");

const imgui_sources = [_][]const u8{
    "cimgui.cpp",
    "cimgui_internal.cpp",
    "imgui_demo.cpp",
    "imgui_draw.cpp",
    "imgui_tables.cpp",
    "imgui_widgets.cpp",
    "imgui.cpp",
};

// returned by the getConfig() helper function to get a matching
// set of module name, C header path and C library name for
// vanilla imgui vs imgui docking branch (because mismatches
// may appear to build but then cause hilarious runtime bugs)
pub const Config = struct {
    module_name: []const u8, // cimgui or cimgui_docking
    include_dir: []const u8, // src or src-docking
};

// helper function to return a matching set of Zig module name,
// C header search path and C library name for docking vs non-docking
pub fn getConfig(docking: bool) Config {
    if (docking) {
        return .{
            .module_name = "cimgui_docking",
            .include_dir = "src-docking",
        };
    } else {
        return .{
            .module_name = "cimgui",
            .include_dir = "src",
        };
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const opt_clib_include_path = b.option(std.Build.LazyPath, "clib_include_path", "");

    // the regular imgui module
    try buildModule(b, .{
        .modname = "cimgui",
        .subdir = "src",
        .sources = &imgui_sources,
        .target = target,
        .optimize = optimize,
        .system_include_paths = if (opt_clib_include_path) |path| &.{path} else &.{},
    });

    // ...and the imgui_docking module
    try buildModule(b, .{
        .modname = "cimgui_docking",
        .subdir = "src-docking",
        .sources = &imgui_sources,
        .target = target,
        .optimize = optimize,
        .system_include_paths = if (opt_clib_include_path) |path| &.{path} else &.{},
    });
}

const BuildModuleOptions = struct {
    modname: []const u8,
    subdir: []const u8,
    sources: []const []const u8,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    system_include_paths: []const std.Build.LazyPath = &.{},
};

fn buildModule(b: *std.Build, opts: BuildModuleOptions) !void {
    // translate-c the cimgui.h file for the generated bindings
    // NOTE: DO NOT USE cimgui_all.h HERE SINCE IT PULLS IN cimgui_internal.h
    // which doesn't work with Zig's translateC step because this
    // pulls in C bitfields which are not supported by translateC
    const c_bindings = b.addTranslateC(.{
        .root_source_file = b.path(b.fmt("{s}/cimgui.h", .{opts.subdir})),
        .target = opts.target,
        .optimize = opts.optimize,
        .link_libc = true,
    });
    for (opts.system_include_paths) |system_include|
        c_bindings.addSystemIncludePath(system_include);

    const mod = c_bindings.addModule(opts.modname);

    // Compile the imgui sources into the module
    var cflags_buf: [16][]const u8 = undefined;
    var cflags = std.ArrayListUnmanaged([]const u8).initBuffer(&cflags_buf);
    if (opts.target.result.cpu.arch.isWasm()) {
        // on WASM, switch off UBSAN (zig-cc enables this by default in debug mode)
        // but it requires linking with an ubsan runtime)
        try cflags.appendBounded("-fno-sanitize=undefined");
    }
    for (opts.system_include_paths) |system_include|
        mod.addSystemIncludePath(system_include);
    for (imgui_sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(b.fmt("{s}/{s}", .{ opts.subdir, src })),
            .flags = cflags.items,
        });
    }
}

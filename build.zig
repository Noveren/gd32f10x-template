
const std = @import("std");

pub fn build(b: *std.Build) !void {
    // const project = gd32f10x.project(b, .{
    //     .name = "hello",
    //     .lib_root = "src/gd32f10x",
    //     .serial = .GD32F103C8T6,
    // });
    // project.use_std(.{

    // });
    // b.installArtifact(project.elf);

    const elf = try gd32f10x.addExecutable(b, .{
        .name = "hello",
        .lib_root = "src/gd32f10x",
        .serial = .GD32F103C8T6,
    });
    b.installArtifact(elf);

    const clangd_emit = b.option(bool, "clangd", "Enable to generate clangd config file") orelse false;
    if (clangd_emit) {
        try clangd.CompileCommandsJson.generate(b, elf.root_module, .{});
    }
}

const gd32f10x = struct {
    const Options = struct {
        name: []const u8,
        serial: Serial,
        lib_root: ?[]const u8 = null,
        strip: ?bool = null,
    };

    const Serial = enum {
        GD32F103C8T6,
    };

    fn cortex_m3(b: *std.Build) std.Build.ResolvedTarget {
        return b.resolveTargetQuery(.{
            .cpu_arch = .thumb,
            .os_tag = .freestanding,
            .abi = .eabi,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m3 },
        });
    }

    const Context = struct {
        b: *std.Build,
        elf: *std.Build.Step.Compile,
        lib_root: []const u8,

        fn path(ctx: Context, sub_path: []const u8) std.Build.LazyPath {
            return ctx.b.path(ctx.b.fmt("{s}/{s}", .{ ctx.lib_root, sub_path }));
        }

        fn addIncludePath(ctx: Context, sub_path: []const u8) void {
            ctx.elf.addIncludePath(ctx.path(sub_path));
        }

        fn load_core(ctx: Context) void {
            ctx.addIncludePath("core");
        }

        fn load_std(ctx: Context) void {
            ctx.addIncludePath("std/inc");
        }
    };



    fn addExecutable(b: *std.Build, options: Options) !*std.Build.Step.Compile {
        const target = cortex_m3(b);
        const optimize = b.standardOptimizeOption(.{});

        const elf = b.addExecutable(.{
            .name = options.name,
            .target = target,
            .optimize = optimize,
            .link_libc = false,
            .linkage = .static,
            .single_threaded = true,
            .strip = options.strip orelse false,
            .error_tracing = false,
        });

        const ctx = Context {
            .b = b,
            .elf = elf,
            .lib_root = options.lib_root orelse "gd32f10x",
        };

        ctx.load_core();
        ctx.load_std();

        // 添加标准外设库头文件与源文件
        elf.addIncludePath(b.path("src/gd32f10x/std/inc"));
        try addCSourceFileInDir(b, elf, "src/gd32f10x/std/src", &[_][]const u8 {
            "gd32f10x_can.c", // DBG
            "gd32f10x_enet.c",
        });

        // 添加标准外设库接口头文件
        // 添加系统时钟初始化 system_gd32f10x.c，并启用实现其需要的最少外设
        elf.addIncludePath(b.path("src/gd32f10x"));
        elf.defineCMacro("GD32F10X_USE_FMC", null);
        elf.defineCMacro("GD32F10X_USE_RCU", null);
        elf.defineCMacro("GD32F10X_USE_MISC", null);
        elf.addCSourceFile(.{ .file = b.path("src/gd32f10x/system_gd32f10x.c") });

        // ======================================
        switch (options.serial) {
            .GD32F103C8T6 => {
                elf.defineCMacro("GD32F10X_MD", null);
            }
        }

        const root: []const u8 = b.pathFromRoot(".");
        const relative_app: []const u8 = b.fmt("src/{s}", .{ options.name });
        const absolute_app: []const u8 = try std.fs.path.resolve(b.allocator, &[_][]const u8 {
            root, relative_app
        });
        defer b.allocator.free(absolute_app);

        // 检查或创建用户项目根目录 `src/{options.name}`
        _ = try utils.checkOrCreateDir(absolute_app);

        // TODO 生成链接脚本
        elf.setLinkerScript(b.path(b.fmt("{s}/{s}", .{ relative_app, "linker.ld" })));
        elf.entry = .{ .symbol_name = "Reset_Handler" };
        elf.link_gc_sections = true;

        // TODO 生成启动文件
        elf.addAssemblyFile(b.path(b.fmt("{s}/{s}", .{ relative_app, "startup.s" })));

        // 添加头文件路径, 搜索并添加源文件
        elf.addIncludePath(b.path(relative_app));
        try addCSourceFileInDir(b, elf, relative_app, null);

        return elf;
    }

    fn addCSourceFileInDir(
        b: *std.Build,
        elf: *std.Build.Step.Compile,
        relative_path: []const u8,
        exclude_filenames: ?[]const []const u8
    ) !void {
        const root: []const u8 = b.pathFromRoot(".");
        const absolute_path: []const u8 = try std.fs.path.resolve(b.allocator, &[_][]const u8 {
            root, relative_path
        });
        defer b.allocator.free(absolute_path);

        const source_filenames = try utils.findFileWithExtension(b.allocator, absolute_path, ".c");
        defer source_filenames.deinit();
        var source_filenames_iter = std.mem.splitSequence(u8, source_filenames.items, ", ");
        while (source_filenames_iter.next()) |source_filename| {
            var is_exclude: bool = false;
            if (exclude_filenames) |_exclude_filenames| {
                for (_exclude_filenames) |exclude_filename| {
                    is_exclude = std.mem.eql(u8, source_filename, exclude_filename);
                    if (is_exclude) break;
                }
            }
            if (is_exclude) continue;

            const relative_source_file = b.fmt("{s}/{s}", .{ relative_path, source_filename });
            std.log.debug("{s}", .{ relative_source_file });
            elf.addCSourceFile(.{ .file = b.path(relative_source_file) });
        }
    }
};

const utils = struct {
    fn println_s(string: []const u8) void {
        std.debug.print("{s}\n", .{ string });
    }

    pub fn findFileWithExtension(
        allocator: std.mem.Allocator,
        absolute_path: []const u8,
        extension: []const u8,
    ) (std.fs.File.OpenError || std.fs.Dir.Iterator.Error || std.mem.Allocator.Error)!std.ArrayList(u8) {
        var dir = try std.fs.openDirAbsolute(absolute_path, .{ .iterate = true });
        defer dir.close();

        var collect = std.ArrayList(u8).init(allocator);

        var dir_iter = dir.iterate();
        while (dir_iter.next()) |i| {
            const entry = i orelse break;
            const is_file_with_extension = switch (entry.kind) {
                else => false,
                .file => std.mem.eql(u8, extension, std.fs.path.extension(entry.name)),
            };
            if (is_file_with_extension) {
                if (collect.items.len > 0) {
                    try collect.appendSlice(", ");
                }
                try collect.appendSlice(entry.name);
            }
        } else |err| { return err; }
        return collect;
    }

    pub fn checkOrCreateDir(absolute_path: []const u8) std.posix.MakeDirError!bool {
        return if (std.fs.makeDirAbsolute(absolute_path)) |_| true else |err| switch (err) {
            std.posix.MakeDirError.PathAlreadyExists => false,
            else => err,
        };
    }

    pub fn exists(absolute_path: []const u8) std.fs.Dir.AccessError!bool {
        return if (std.fs.accessAbsolute(absolute_path, .{})) |_| true else |err| switch (err) {
            std.fs.Dir.AccessError.FileNotFound => false,
            else => err,
        };
    }
};

const clangd = struct {
    fn getZigRootPath(b: *std.Build) ![]const u8 {
        const zig_exe_path = try b.findProgram(&.{"zig"}, &.{});
        const zig_root_path = std.fs.path.dirname(zig_exe_path);
        return zig_root_path orelse error.Failed;
    }

    pub const CompileCommandsJson = struct {
        const Item = struct {
            arguments: []const []const u8,
            directory: []const u8,
            file: []const u8,
        };

        pub const GenerateOptions = struct {
            cstd: ?CStd = null,

            const CStd = union(enum) {
                // $zig_root_path$/lib/libc/include/$arch_os_abi$
                Libc: []const u8,
                // $zig_root_path$/lib/libcxx/include
                Libcxx,
            };
        };

        pub fn generate(
            b: *std.Build,
            module: std.Build.Module,
            options: GenerateOptions,
        ) !void {
            const systemIncludeDir: [3]?[]const u8 = blk: {
                var ret: [3]?[]const u8 = .{ null, null, null };
                if (getZigRootPath(b)) |zig_root_path| {
                    // FIXME Zig 与 Clangd 冲突
                    // const zig_cc_builtin_include_path = try std.fs.path.resolve(b.allocator, &[_][]const u8 {
                    //     zig_root_path,
                    //     "lib/include"
                    // });
                    // ret[0] = zig_cc_builtin_include_path;

                    if (options.cstd) |cstd| {
                        switch (cstd) {
                            .Libc => |arch_os_abi| {
                                const libc_include_path = try std.fs.path.resolve(b.allocator, &[_][]const u8 {
                                    zig_root_path,
                                    "lib/libc/include",
                                    arch_os_abi,
                                });
                                ret[1] = libc_include_path;
                            },
                            .Libcxx => {
                                ret[2] = try std.fs.path.resolve(b.allocator, &[_][]const u8 {
                                    zig_root_path,
                                    "lib/libcxx/include"
                                });
                            }
                        }
                    }
                } else |_| {
                    std.log.err("Failed to get zig_root_path\n", .{});
                }
                break :blk ret;
            };

            const cwd = try std.fs.cwd().realpathAlloc(b.allocator, ".");
            defer b.allocator.free(cwd);

            const c_macros = module.c_macros.items;
            const include_dirs = blk: {
                var ret = std.ArrayList([]const u8).init(b.allocator);
                for (module.include_dirs.items) |include_dir| {
                    switch (include_dir) {
                        .path,
                        .path_system,
                        .path_after,
                        .framework_path,
                        .framework_path_system => |p| {
                            try ret.append(p.getPath(b));
                        },
                        .other_step => {},
                        .config_header_step => {},
                    }
                }
                break :blk ret;
            };
            defer include_dirs.deinit();

            var data = std.ArrayList(Item).init(b.allocator);
            defer data.deinit();

            // 未对 Item 内存进行设计和管理（释放）
            for (module.link_objects.items) |link_object| {
                switch (link_object) {
                    else => {},
                    .c_source_file => |csf| {
                        const file_relative_path = try std.fs.path.relative(b.allocator, cwd, csf.file.getPath(b));

                        var arguments = std.ArrayList([]const u8).init(b.allocator);
                        try arguments.append("zig cc");                 // Compiler
                        try arguments.append(file_relative_path);       // SourceFile

                        for (csf.flags) |flag| {
                            try arguments.append(flag);
                        }

                        try arguments.append("-D__GNUC__");
                        for (c_macros) |c_macro| {
                            try arguments.append(c_macro);
                        }

                        for (systemIncludeDir) |sid| {
                            if (sid) |_sid| {
                                try arguments.append(b.fmt("-I{s}", .{_sid}));
                            }
                        }
                        for (include_dirs.items) |include_dir| {
                            const dir_relative = try std.fs.path.relative(b.allocator, cwd, include_dir);
                            try arguments.append(b.fmt("-I{s}", .{dir_relative}));
                        }

                        const item = Item {
                            .arguments = arguments.items,
                            .directory = cwd,
                            .file = file_relative_path,
                        };
                        try data.append(item);
                    }
                }
            }

            const json_string = try std.json.stringifyAlloc(b.allocator, data.items, .{
                .whitespace = .indent_4,
            });
            defer b.allocator.free(json_string);

            const json_file = try std.fs.cwd().createFile("compile_commands.json", .{});
            _ = try json_file.write(json_string);
        }
    };
};
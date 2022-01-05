const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *Builder) void {
    const kernel = b.addExecutable("kernel", "src/main.zig");
    kernel.addPackagePath("kernel", "src/index.zig");
    kernel.addPackagePath("x86", "src/arch/x86/index.zig");
    kernel.setOutputDir("build");

    kernel.addAssemblyFile("src/arch/x86/start.s");
    kernel.addAssemblyFile("src/arch/x86/gdt.s");
    kernel.addAssemblyFile("src/arch/x86/isr.s");
    kernel.addAssemblyFile("src/arch/x86/paging.s");
    kernel.addAssemblyFile("src/arch/x86/switch_tasks.s");

    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setTarget(std.zig.CrossTarget{
            .cpu_arch = std.Target.Cpu.Arch.i386,
            //.Arch = std.Target.Arch.i386,
            .os_tag = std.Target.Os.Tag.freestanding,
            //.os = std.Target.Os.freestanding,
            .abi = std.Target.Abi.none,
            //.cpu_features = std.Target.CpuFeatures.initFromCpu(
                //builtin.Arch.i386,
                //&builtin.Target.x86.cpu._i686,
            //),
    });
    kernel.setLinkerScriptPath(std.build.FileSource{.path = "src/arch/x86/linker.ld"});
    b.default_step.dependOn(&kernel.step);
}

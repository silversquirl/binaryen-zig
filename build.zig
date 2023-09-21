const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const assertions = b.option(bool, "assertions", "Enable assertions (default: true)") orelse true;
    const dwarf = b.option(bool, "dwarf", "Enable full DWARF support") orelse true;

    const lib = b.addStaticLibrary(.{
        .name = "binaryen",
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "wasm_intrinsics.zig" },
    });
    const t = lib.target_info.target;

    lib.defineCMacro("BUILD_STATIC_LIBRARY", null);

    lib.addIncludePath(.{ .path = "src" });
    if (dwarf) {
        lib.defineCMacro("BUILD_LLVM_DWARF", null);
        lib.addIncludePath(.{ .path = "third_party/llvm-project/include" });
    }
    if (!assertions) {
        lib.defineCMacro("NDEBUG", null);
    }

    const flags: []const []const u8 = &.{
        "-std=c++17",

        "-Wall",
        "-Werror",
        "-Wno-unused-parameter",
        "-Wno-omit-frame-pointer",
        "-Wswitch",
        "-Wimplicit-fallthrough",
        "-Wnon-virtual-dtor",

        "-fno-rtti",
        "-fPIC",

        // TODO: remove once this is resolved: https://github.com/WebAssembly/binaryen/pull/2314
        "-Wno-implicit-int-float-conversion",
        "-Wno-unknown-warning-option",

        // FIXME: only needed in release
        "-Wno-unused-but-set-variable",
    };

    // TODO: wasm target? Might require emscripten though

    if (t.os.tag == .windows) {
        lib.defineCMacro("_GNU_SOURCE", null);
        lib.defineCMacro("__STDC_FORMAT_MACROS", null);
        // TODO: -wl,/stack:8388608
    }

    lib.addCSourceFiles(&.{
        "src/ir/ExpressionAnalyzer.cpp",
        "src/ir/ExpressionManipulator.cpp",
        "src/ir/drop.cpp",
        "src/ir/eh-utils.cpp",
        "src/ir/export-utils.cpp",
        "src/ir/intrinsics.cpp",
        "src/ir/lubs.cpp",
        "src/ir/memory-utils.cpp",
        "src/ir/module-utils.cpp",
        "src/ir/names.cpp",
        "src/ir/possible-contents.cpp",
        "src/ir/properties.cpp",
        "src/ir/LocalGraph.cpp",
        "src/ir/LocalStructuralDominance.cpp",
        "src/ir/ReFinalize.cpp",
        "src/ir/stack-utils.cpp",
        "src/ir/table-utils.cpp",
        "src/ir/type-updating.cpp",
        "src/ir/module-splitting.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "src/asmjs/asm_v_wasm.cpp",
        "src/asmjs/asmangle.cpp",
        "src/asmjs/shared-constants.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "src/cfg/Relooper.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "src/emscripten-optimizer/optimizer-shared.cpp",
        "src/emscripten-optimizer/parser.cpp",
        "src/emscripten-optimizer/simple_ast.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "wasm_intrinsics.cpp",

        "src/passes/param-utils.cpp",
        "src/passes/pass.cpp",
        "src/passes/test_passes.cpp",
        "src/passes/AbstractTypeRefining.cpp",
        "src/passes/AlignmentLowering.cpp",
        "src/passes/Asyncify.cpp",
        "src/passes/AvoidReinterprets.cpp",
        "src/passes/CoalesceLocals.cpp",
        "src/passes/CodePushing.cpp",
        "src/passes/CodeFolding.cpp",
        "src/passes/ConstantFieldPropagation.cpp",
        "src/passes/ConstHoisting.cpp",
        "src/passes/DataFlowOpts.cpp",
        "src/passes/DeadArgumentElimination.cpp",
        "src/passes/DeadCodeElimination.cpp",
        "src/passes/DeAlign.cpp",
        "src/passes/DeNaN.cpp",
        "src/passes/Directize.cpp",
        "src/passes/DuplicateImportElimination.cpp",
        "src/passes/DuplicateFunctionElimination.cpp",
        "src/passes/DWARF.cpp",
        "src/passes/ExtractFunction.cpp",
        "src/passes/Flatten.cpp",
        "src/passes/FuncCastEmulation.cpp",
        "src/passes/GenerateDynCalls.cpp",
        "src/passes/GlobalEffects.cpp",
        "src/passes/GlobalRefining.cpp",
        "src/passes/GlobalStructInference.cpp",
        "src/passes/GlobalTypeOptimization.cpp",
        "src/passes/GUFA.cpp",
        "src/passes/Heap2Local.cpp",
        "src/passes/I64ToI32Lowering.cpp",
        "src/passes/Inlining.cpp",
        "src/passes/InstrumentLocals.cpp",
        "src/passes/InstrumentMemory.cpp",
        "src/passes/Intrinsics.cpp",
        "src/passes/JSPI.cpp",
        "src/passes/LegalizeJSInterface.cpp",
        "src/passes/LimitSegments.cpp",
        "src/passes/LocalCSE.cpp",
        "src/passes/LocalSubtyping.cpp",
        "src/passes/LogExecution.cpp",
        "src/passes/LoopInvariantCodeMotion.cpp",
        "src/passes/Memory64Lowering.cpp",
        "src/passes/MemoryPacking.cpp",
        "src/passes/MergeBlocks.cpp",
        "src/passes/MergeSimilarFunctions.cpp",
        "src/passes/MergeLocals.cpp",
        "src/passes/Metrics.cpp",
        "src/passes/MinifyImportsAndExports.cpp",
        "src/passes/Monomorphize.cpp",
        "src/passes/MultiMemoryLowering.cpp",
        "src/passes/NameList.cpp",
        "src/passes/NameTypes.cpp",
        "src/passes/OnceReduction.cpp",
        "src/passes/OptimizeAddedConstants.cpp",
        "src/passes/OptimizeCasts.cpp",
        "src/passes/OptimizeInstructions.cpp",
        "src/passes/OptimizeForJS.cpp",
        "src/passes/PickLoadSigns.cpp",
        "src/passes/Poppify.cpp",
        "src/passes/PostEmscripten.cpp",
        "src/passes/Precompute.cpp",
        "src/passes/Print.cpp",
        "src/passes/PrintCallGraph.cpp",
        "src/passes/PrintFeatures.cpp",
        "src/passes/PrintFunctionMap.cpp",
        "src/passes/RoundTrip.cpp",
        "src/passes/SetGlobals.cpp",
        "src/passes/StackIR.cpp",
        "src/passes/SignaturePruning.cpp",
        "src/passes/SignatureRefining.cpp",
        "src/passes/SignExtLowering.cpp",
        "src/passes/Strip.cpp",
        "src/passes/StripTargetFeatures.cpp",
        "src/passes/RedundantSetElimination.cpp",
        "src/passes/RemoveImports.cpp",
        "src/passes/RemoveMemory.cpp",
        "src/passes/RemoveNonJSOps.cpp",
        "src/passes/RemoveUnusedBrs.cpp",
        "src/passes/RemoveUnusedNames.cpp",
        "src/passes/RemoveUnusedModuleElements.cpp",
        "src/passes/RemoveUnusedTypes.cpp",
        "src/passes/ReorderFunctions.cpp",
        "src/passes/ReorderGlobals.cpp",
        "src/passes/ReorderLocals.cpp",
        "src/passes/ReReloop.cpp",
        "src/passes/TrapMode.cpp",
        "src/passes/TypeRefining.cpp",
        "src/passes/TypeMerging.cpp",
        "src/passes/TypeSSA.cpp",
        "src/passes/SafeHeap.cpp",
        "src/passes/SimplifyGlobals.cpp",
        "src/passes/SimplifyLocals.cpp",
        "src/passes/Souperify.cpp",
        "src/passes/SpillPointers.cpp",
        "src/passes/StackCheck.cpp",
        "src/passes/SSAify.cpp",
        "src/passes/Untee.cpp",
        "src/passes/Vacuum.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "src/support/archive.cpp",
        "src/support/bits.cpp",
        "src/support/colors.cpp",
        //"src/support/command-line.cpp", // We don't build tools so no need for this
        "src/support/debug.cpp",
        "src/support/dfa_minimization.cpp",
        "src/support/file.cpp",
        "src/support/istring.cpp",
        "src/support/path.cpp",
        "src/support/safe_integer.cpp",
        "src/support/threads.cpp",
        "src/support/utilities.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "src/wasm/literal.cpp",
        "src/wasm/parsing.cpp",
        "src/wasm/wasm.cpp",
        "src/wasm/wasm-binary.cpp",
        "src/wasm/wasm-emscripten.cpp",
        "src/wasm/wasm-interpreter.cpp",
        "src/wasm/wasm-io.cpp",
        "src/wasm/wasm-s-parser.cpp",
        "src/wasm/wasm-stack.cpp",
        "src/wasm/wasm-type.cpp",
        "src/wasm/wasm-validator.cpp",
        "src/wasm/wat-lexer.cpp",
        "src/wasm/wat-parser.cpp",
    }, flags);
    // wasm-debug.cpp includes LLVM header using std::iterator (deprecated in C++17)
    lib.addCSourceFile(.{
        .file = .{ .path = "src/wasm/wasm-debug.cpp" },
        .flags = extraFlags(b, flags, &.{"-Wno-deprecated-declarations"}),
    });

    if (dwarf) {
        lib.addCSourceFiles(&.{
            "third_party/llvm-project/Binary.cpp",
            "third_party/llvm-project/ConvertUTF.cpp",
            "third_party/llvm-project/DataExtractor.cpp",
            "third_party/llvm-project/Debug.cpp",
            "third_party/llvm-project/DJB.cpp",
            "third_party/llvm-project/Dwarf.cpp",
            "third_party/llvm-project/dwarf2yaml.cpp",
            "third_party/llvm-project/DWARFAbbreviationDeclaration.cpp",
            "third_party/llvm-project/DWARFAcceleratorTable.cpp",
            "third_party/llvm-project/DWARFAddressRange.cpp",
            "third_party/llvm-project/DWARFCompileUnit.cpp",
            "third_party/llvm-project/DWARFContext.cpp",
            "third_party/llvm-project/DWARFDataExtractor.cpp",
            "third_party/llvm-project/DWARFDebugAbbrev.cpp",
            "third_party/llvm-project/DWARFDebugAddr.cpp",
            "third_party/llvm-project/DWARFDebugAranges.cpp",
            "third_party/llvm-project/DWARFDebugArangeSet.cpp",
            "third_party/llvm-project/DWARFDebugFrame.cpp",
            "third_party/llvm-project/DWARFDebugInfoEntry.cpp",
            "third_party/llvm-project/DWARFDebugLine.cpp",
            "third_party/llvm-project/DWARFDebugLoc.cpp",
            "third_party/llvm-project/DWARFDebugMacro.cpp",
            "third_party/llvm-project/DWARFDebugPubTable.cpp",
            "third_party/llvm-project/DWARFDebugRangeList.cpp",
            "third_party/llvm-project/DWARFDebugRnglists.cpp",
            "third_party/llvm-project/DWARFDie.cpp",
            "third_party/llvm-project/DWARFEmitter.cpp",
            "third_party/llvm-project/DWARFExpression.cpp",
            "third_party/llvm-project/DWARFFormValue.cpp",
            "third_party/llvm-project/DWARFGdbIndex.cpp",
            "third_party/llvm-project/DWARFListTable.cpp",
            "third_party/llvm-project/DWARFTypeUnit.cpp",
            "third_party/llvm-project/DWARFUnit.cpp",
            "third_party/llvm-project/DWARFUnitIndex.cpp",
            "third_party/llvm-project/DWARFVerifier.cpp",
            "third_party/llvm-project/DWARFVisitor.cpp",
            "third_party/llvm-project/DWARFYAML.cpp",
            "third_party/llvm-project/Error.cpp",
            "third_party/llvm-project/ErrorHandling.cpp",
            "third_party/llvm-project/FormatVariadic.cpp",
            "third_party/llvm-project/Hashing.cpp",
            "third_party/llvm-project/LEB128.cpp",
            "third_party/llvm-project/LineIterator.cpp",
            "third_party/llvm-project/MCRegisterInfo.cpp",
            "third_party/llvm-project/MD5.cpp",
            "third_party/llvm-project/MemoryBuffer.cpp",
            "third_party/llvm-project/NativeFormatting.cpp",
            "third_party/llvm-project/ObjectFile.cpp",
            "third_party/llvm-project/obj2yaml_Error.cpp",
            "third_party/llvm-project/Optional.cpp",
            "third_party/llvm-project/Path.cpp",
            "third_party/llvm-project/raw_ostream.cpp",
            "third_party/llvm-project/ScopedPrinter.cpp",
            "third_party/llvm-project/SmallVector.cpp",
            "third_party/llvm-project/SourceMgr.cpp",
            "third_party/llvm-project/StringMap.cpp",
            "third_party/llvm-project/StringRef.cpp",
            "third_party/llvm-project/SymbolicFile.cpp",
            "third_party/llvm-project/Twine.cpp",
            "third_party/llvm-project/UnicodeCaseFold.cpp",
            "third_party/llvm-project/WithColor.cpp",
            "third_party/llvm-project/YAMLParser.cpp", // XXX: needed?
            "third_party/llvm-project/YAMLTraits.cpp",
        }, extraFlags(b, flags, &.{
            "-w",
            "-std=c++14",
            "-D_GNU_SOURCE",
            "-D_DEBUG",
            "-D__STDC_CONSTANT_MACROS",
            "-D__STDC_FORMAT_MACROS",
            "-D__STDC_LIMIT_MACROS",
        }));
    }

    lib.addCSourceFile(.{
        .file = .{ .path = "src/binaryen-c.cpp" },
        .flags = flags,
    });

    lib.linkLibC();
    lib.linkLibCpp();
    b.installArtifact(lib);
    lib.installHeader("src/binaryen-c.h", "binaryen/binaryen.h");
    lib.installHeader("src/wasm-delegations.def", "binaryen/wasm-delegations.def");

    const mod = b.addModule("binaryen", .{
        .source_file = .{ .path = "binaryen.zig" },
    });
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "test.zig" },
    });
    tests.addModule("binaryen", mod);
    tests.linkLibC();
    tests.linkLibrary(lib);

    b.step("test", "run wrapper library tests").dependOn(&b.addRunArtifact(tests).step);
}

fn extraFlags(b: *std.Build, flags: []const []const u8, more: []const []const u8) []const []const u8 {
    return std.mem.concat(b.allocator, []const u8, &.{ flags, more }) catch @panic("OOM");
}

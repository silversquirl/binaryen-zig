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

    lib.addIncludePath("binaryen/src");
    if (dwarf) {
        lib.defineCMacro("BUILD_LLVM_DWARF", null);
        lib.addIncludePath("binaryen/third_party/llvm-project/include");
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
    };

    // TODO: wasm target? Might require emscripten though

    if (t.os.tag == .windows) {
        lib.defineCMacro("_GNU_SOURCE", null);
        lib.defineCMacro("__STDC_FORMAT_MACROS", null);
        // TODO: -wl,/stack:8388608
    }

    lib.addCSourceFiles(&.{
        "binaryen/src/ir/ExpressionAnalyzer.cpp",
        "binaryen/src/ir/ExpressionManipulator.cpp",
        "binaryen/src/ir/drop.cpp",
        "binaryen/src/ir/eh-utils.cpp",
        "binaryen/src/ir/export-utils.cpp",
        "binaryen/src/ir/intrinsics.cpp",
        "binaryen/src/ir/lubs.cpp",
        "binaryen/src/ir/memory-utils.cpp",
        "binaryen/src/ir/module-utils.cpp",
        "binaryen/src/ir/names.cpp",
        "binaryen/src/ir/possible-contents.cpp",
        "binaryen/src/ir/properties.cpp",
        "binaryen/src/ir/LocalGraph.cpp",
        "binaryen/src/ir/LocalStructuralDominance.cpp",
        "binaryen/src/ir/ReFinalize.cpp",
        "binaryen/src/ir/stack-utils.cpp",
        "binaryen/src/ir/table-utils.cpp",
        "binaryen/src/ir/type-updating.cpp",
        "binaryen/src/ir/module-splitting.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "binaryen/src/asmjs/asm_v_wasm.cpp",
        "binaryen/src/asmjs/asmangle.cpp",
        "binaryen/src/asmjs/shared-constants.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "binaryen/src/cfg/Relooper.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "binaryen/src/emscripten-optimizer/optimizer-shared.cpp",
        "binaryen/src/emscripten-optimizer/parser.cpp",
        "binaryen/src/emscripten-optimizer/simple_ast.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "wasm_intrinsics.cpp",

        "binaryen/src/passes/param-utils.cpp",
        "binaryen/src/passes/pass.cpp",
        "binaryen/src/passes/test_passes.cpp",
        "binaryen/src/passes/AbstractTypeRefining.cpp",
        "binaryen/src/passes/AlignmentLowering.cpp",
        "binaryen/src/passes/Asyncify.cpp",
        "binaryen/src/passes/AvoidReinterprets.cpp",
        "binaryen/src/passes/CoalesceLocals.cpp",
        "binaryen/src/passes/CodePushing.cpp",
        "binaryen/src/passes/CodeFolding.cpp",
        "binaryen/src/passes/ConstantFieldPropagation.cpp",
        "binaryen/src/passes/ConstHoisting.cpp",
        "binaryen/src/passes/DataFlowOpts.cpp",
        "binaryen/src/passes/DeadArgumentElimination.cpp",
        "binaryen/src/passes/DeadCodeElimination.cpp",
        "binaryen/src/passes/DeAlign.cpp",
        "binaryen/src/passes/DeNaN.cpp",
        "binaryen/src/passes/Directize.cpp",
        "binaryen/src/passes/DuplicateImportElimination.cpp",
        "binaryen/src/passes/DuplicateFunctionElimination.cpp",
        "binaryen/src/passes/DWARF.cpp",
        "binaryen/src/passes/ExtractFunction.cpp",
        "binaryen/src/passes/Flatten.cpp",
        "binaryen/src/passes/FuncCastEmulation.cpp",
        "binaryen/src/passes/GenerateDynCalls.cpp",
        "binaryen/src/passes/GlobalEffects.cpp",
        "binaryen/src/passes/GlobalRefining.cpp",
        "binaryen/src/passes/GlobalStructInference.cpp",
        "binaryen/src/passes/GlobalTypeOptimization.cpp",
        "binaryen/src/passes/GUFA.cpp",
        "binaryen/src/passes/Heap2Local.cpp",
        "binaryen/src/passes/I64ToI32Lowering.cpp",
        "binaryen/src/passes/Inlining.cpp",
        "binaryen/src/passes/InstrumentLocals.cpp",
        "binaryen/src/passes/InstrumentMemory.cpp",
        "binaryen/src/passes/Intrinsics.cpp",
        "binaryen/src/passes/JSPI.cpp",
        "binaryen/src/passes/LegalizeJSInterface.cpp",
        "binaryen/src/passes/LimitSegments.cpp",
        "binaryen/src/passes/LocalCSE.cpp",
        "binaryen/src/passes/LocalSubtyping.cpp",
        "binaryen/src/passes/LogExecution.cpp",
        "binaryen/src/passes/LoopInvariantCodeMotion.cpp",
        "binaryen/src/passes/Memory64Lowering.cpp",
        "binaryen/src/passes/MemoryPacking.cpp",
        "binaryen/src/passes/MergeBlocks.cpp",
        "binaryen/src/passes/MergeSimilarFunctions.cpp",
        "binaryen/src/passes/MergeLocals.cpp",
        "binaryen/src/passes/Metrics.cpp",
        "binaryen/src/passes/MinifyImportsAndExports.cpp",
        "binaryen/src/passes/Monomorphize.cpp",
        "binaryen/src/passes/MultiMemoryLowering.cpp",
        "binaryen/src/passes/NameList.cpp",
        "binaryen/src/passes/NameTypes.cpp",
        "binaryen/src/passes/OnceReduction.cpp",
        "binaryen/src/passes/OptimizeAddedConstants.cpp",
        "binaryen/src/passes/OptimizeCasts.cpp",
        "binaryen/src/passes/OptimizeInstructions.cpp",
        "binaryen/src/passes/OptimizeForJS.cpp",
        "binaryen/src/passes/PickLoadSigns.cpp",
        "binaryen/src/passes/Poppify.cpp",
        "binaryen/src/passes/PostEmscripten.cpp",
        "binaryen/src/passes/Precompute.cpp",
        "binaryen/src/passes/Print.cpp",
        "binaryen/src/passes/PrintCallGraph.cpp",
        "binaryen/src/passes/PrintFeatures.cpp",
        "binaryen/src/passes/PrintFunctionMap.cpp",
        "binaryen/src/passes/RoundTrip.cpp",
        "binaryen/src/passes/SetGlobals.cpp",
        "binaryen/src/passes/StackIR.cpp",
        "binaryen/src/passes/SignaturePruning.cpp",
        "binaryen/src/passes/SignatureRefining.cpp",
        "binaryen/src/passes/SignExtLowering.cpp",
        "binaryen/src/passes/Strip.cpp",
        "binaryen/src/passes/StripTargetFeatures.cpp",
        "binaryen/src/passes/RedundantSetElimination.cpp",
        "binaryen/src/passes/RemoveImports.cpp",
        "binaryen/src/passes/RemoveMemory.cpp",
        "binaryen/src/passes/RemoveNonJSOps.cpp",
        "binaryen/src/passes/RemoveUnusedBrs.cpp",
        "binaryen/src/passes/RemoveUnusedNames.cpp",
        "binaryen/src/passes/RemoveUnusedModuleElements.cpp",
        "binaryen/src/passes/RemoveUnusedTypes.cpp",
        "binaryen/src/passes/ReorderFunctions.cpp",
        "binaryen/src/passes/ReorderGlobals.cpp",
        "binaryen/src/passes/ReorderLocals.cpp",
        "binaryen/src/passes/ReReloop.cpp",
        "binaryen/src/passes/TrapMode.cpp",
        "binaryen/src/passes/TypeRefining.cpp",
        "binaryen/src/passes/TypeMerging.cpp",
        "binaryen/src/passes/TypeSSA.cpp",
        "binaryen/src/passes/SafeHeap.cpp",
        "binaryen/src/passes/SimplifyGlobals.cpp",
        "binaryen/src/passes/SimplifyLocals.cpp",
        "binaryen/src/passes/Souperify.cpp",
        "binaryen/src/passes/SpillPointers.cpp",
        "binaryen/src/passes/StackCheck.cpp",
        "binaryen/src/passes/SSAify.cpp",
        "binaryen/src/passes/Untee.cpp",
        "binaryen/src/passes/Vacuum.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "binaryen/src/support/archive.cpp",
        "binaryen/src/support/bits.cpp",
        "binaryen/src/support/colors.cpp",
        //"binaryen/src/support/command-line.cpp", // We don't build tools so no need for this
        "binaryen/src/support/debug.cpp",
        "binaryen/src/support/dfa_minimization.cpp",
        "binaryen/src/support/file.cpp",
        "binaryen/src/support/istring.cpp",
        "binaryen/src/support/path.cpp",
        "binaryen/src/support/safe_integer.cpp",
        "binaryen/src/support/threads.cpp",
        "binaryen/src/support/utilities.cpp",
    }, flags);

    lib.addCSourceFiles(&.{
        "binaryen/src/wasm/literal.cpp",
        "binaryen/src/wasm/parsing.cpp",
        "binaryen/src/wasm/wasm.cpp",
        "binaryen/src/wasm/wasm-binary.cpp",
        "binaryen/src/wasm/wasm-emscripten.cpp",
        "binaryen/src/wasm/wasm-interpreter.cpp",
        "binaryen/src/wasm/wasm-io.cpp",
        "binaryen/src/wasm/wasm-s-parser.cpp",
        "binaryen/src/wasm/wasm-stack.cpp",
        "binaryen/src/wasm/wasm-type.cpp",
        "binaryen/src/wasm/wasm-validator.cpp",
        "binaryen/src/wasm/wat-lexer.cpp",
        "binaryen/src/wasm/wat-parser.cpp",
    }, flags);
    // wasm-debug.cpp includes LLVM header using std::iterator (deprecated in C++17)
    lib.addCSourceFile(
        "binaryen/src/wasm/wasm-debug.cpp",
        extraFlags(b, flags, &.{"-Wno-deprecated-declarations"}),
    );

    if (dwarf) {
        lib.addCSourceFiles(&.{
            "binaryen/third_party/llvm-project/Binary.cpp",
            "binaryen/third_party/llvm-project/ConvertUTF.cpp",
            "binaryen/third_party/llvm-project/DataExtractor.cpp",
            "binaryen/third_party/llvm-project/Debug.cpp",
            "binaryen/third_party/llvm-project/DJB.cpp",
            "binaryen/third_party/llvm-project/Dwarf.cpp",
            "binaryen/third_party/llvm-project/dwarf2yaml.cpp",
            "binaryen/third_party/llvm-project/DWARFAbbreviationDeclaration.cpp",
            "binaryen/third_party/llvm-project/DWARFAcceleratorTable.cpp",
            "binaryen/third_party/llvm-project/DWARFAddressRange.cpp",
            "binaryen/third_party/llvm-project/DWARFCompileUnit.cpp",
            "binaryen/third_party/llvm-project/DWARFContext.cpp",
            "binaryen/third_party/llvm-project/DWARFDataExtractor.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugAbbrev.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugAddr.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugAranges.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugArangeSet.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugFrame.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugInfoEntry.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugLine.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugLoc.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugMacro.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugPubTable.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugRangeList.cpp",
            "binaryen/third_party/llvm-project/DWARFDebugRnglists.cpp",
            "binaryen/third_party/llvm-project/DWARFDie.cpp",
            "binaryen/third_party/llvm-project/DWARFEmitter.cpp",
            "binaryen/third_party/llvm-project/DWARFExpression.cpp",
            "binaryen/third_party/llvm-project/DWARFFormValue.cpp",
            "binaryen/third_party/llvm-project/DWARFGdbIndex.cpp",
            "binaryen/third_party/llvm-project/DWARFListTable.cpp",
            "binaryen/third_party/llvm-project/DWARFTypeUnit.cpp",
            "binaryen/third_party/llvm-project/DWARFUnit.cpp",
            "binaryen/third_party/llvm-project/DWARFUnitIndex.cpp",
            "binaryen/third_party/llvm-project/DWARFVerifier.cpp",
            "binaryen/third_party/llvm-project/DWARFVisitor.cpp",
            "binaryen/third_party/llvm-project/DWARFYAML.cpp",
            "binaryen/third_party/llvm-project/Error.cpp",
            "binaryen/third_party/llvm-project/ErrorHandling.cpp",
            "binaryen/third_party/llvm-project/FormatVariadic.cpp",
            "binaryen/third_party/llvm-project/Hashing.cpp",
            "binaryen/third_party/llvm-project/LEB128.cpp",
            "binaryen/third_party/llvm-project/LineIterator.cpp",
            "binaryen/third_party/llvm-project/MCRegisterInfo.cpp",
            "binaryen/third_party/llvm-project/MD5.cpp",
            "binaryen/third_party/llvm-project/MemoryBuffer.cpp",
            "binaryen/third_party/llvm-project/NativeFormatting.cpp",
            "binaryen/third_party/llvm-project/ObjectFile.cpp",
            "binaryen/third_party/llvm-project/obj2yaml_Error.cpp",
            "binaryen/third_party/llvm-project/Optional.cpp",
            "binaryen/third_party/llvm-project/Path.cpp",
            "binaryen/third_party/llvm-project/raw_ostream.cpp",
            "binaryen/third_party/llvm-project/ScopedPrinter.cpp",
            "binaryen/third_party/llvm-project/SmallVector.cpp",
            "binaryen/third_party/llvm-project/SourceMgr.cpp",
            "binaryen/third_party/llvm-project/StringMap.cpp",
            "binaryen/third_party/llvm-project/StringRef.cpp",
            "binaryen/third_party/llvm-project/SymbolicFile.cpp",
            "binaryen/third_party/llvm-project/Twine.cpp",
            "binaryen/third_party/llvm-project/UnicodeCaseFold.cpp",
            "binaryen/third_party/llvm-project/WithColor.cpp",
            "binaryen/third_party/llvm-project/YAMLParser.cpp", // XXX: needed?
            "binaryen/third_party/llvm-project/YAMLTraits.cpp",
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

    lib.addCSourceFile("binaryen/src/binaryen-c.cpp", flags);

    lib.linkLibC();
    lib.linkLibCpp();
    lib.install();
    lib.installHeader("binaryen/src/binaryen-c.h", "binaryen-c.h");
}

fn extraFlags(b: *std.Build, flags: []const []const u8, more: []const []const u8) []const []const u8 {
    return std.mem.concat(b.allocator, []const u8, &.{ flags, more }) catch @panic("OOM");
}

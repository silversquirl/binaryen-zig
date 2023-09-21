const std = @import("std");
const byn = @cImport({
    @cInclude("stdlib.h");
    @cInclude("binaryen/binaryen.h");
});

pub fn freeEmit(buf: []u8) void {
    byn.free(buf.ptr);
}

pub const Module = opaque {
    pub fn init() *Module {
        const mod = byn.BinaryenModuleCreate();
        return @ptrCast(mod);
    }
    pub fn deinit(self: *Module) void {
        byn.BinaryenModuleDispose(self.c());
    }

    // TODO: error handling
    pub fn parseText(wat: [*:0]const u8) *Module {
        const mod = byn.BinaryenModuleParse(wat);
        return @ptrCast(mod);
    }
    // TODO: error handling
    pub fn readBinary(wasm: []const u8) *Module {
        const mod = byn.BinaryenModuleRead(@constCast(wasm.ptr), wasm.len);
        return @ptrCast(mod);
    }

    pub fn emitText(self: *Module) [:0]u8 {
        const buf = byn.BinaryenModuleAllocateAndWriteText(self.c());
        return std.mem.span(buf);
    }
    pub fn emitBinary(self: *Module, source_map_url: ?[*:0]const u8) EmitBinaryResult {
        const result = byn.BinaryenModuleAllocateAndWrite(self.c(), source_map_url);
        const binary_ptr: [*]u8 = @ptrCast(result.binary);
        return .{
            .binary = binary_ptr[0..result.binaryBytes],
            .source_map = std.mem.span(result.sourceMap),
        };
    }
    pub const EmitBinaryResult = struct { binary: []u8, source_map: [:0]u8 };

    pub fn addFunction(
        self: *Module,
        name: [*:0]const u8,
        params: Type,
        results: Type,
        var_types: []const Type,
        body: *Expression,
    ) *Function {
        const func = byn.BinaryenAddFunction(
            self.c(),
            name,
            @intFromEnum(params),
            @intFromEnum(results),
            @constCast(@ptrCast(var_types.ptr)),
            @intCast(var_types.len),
            body.c(),
        );
        return @ptrCast(func);
    }

    inline fn c(self: *Module) byn.BinaryenModuleRef {
        return @ptrCast(self);
    }
};

pub const Expression = opaque {
    inline fn c(self: *Expression) byn.BinaryenExpressionRef {
        return @ptrCast(self);
    }
};

pub const Function = opaque {
    inline fn c(self: *Function) byn.BinaryenFunctionRef {
        return @ptrCast(self);
    }
};

pub const Type = enum(usize) {
    _,

    pub fn none() Type {
        return @enumFromInt(byn.BinaryenTypeNone());
    }
    pub fn int32() Type {
        return @enumFromInt(byn.BinaryenTypeInt32());
    }
    pub fn int64() Type {
        return @enumFromInt(byn.BinaryenTypeInt64());
    }
    pub fn float32() Type {
        return @enumFromInt(byn.BinaryenTypeFloat32());
    }
    pub fn float64() Type {
        return @enumFromInt(byn.BinaryenTypeFloat64());
    }
    pub fn vec128() Type {
        return @enumFromInt(byn.BinaryenTypeVec128());
    }
    pub fn funcref() Type {
        return @enumFromInt(byn.BinaryenTypeFuncref());
    }
    pub fn externref() Type {
        return @enumFromInt(byn.BinaryenTypeExternref());
    }
    pub fn anyref() Type {
        return @enumFromInt(byn.BinaryenTypeAnyref());
    }
    pub fn eqref() Type {
        return @enumFromInt(byn.BinaryenTypeEqref());
    }
    pub fn i31ref() Type {
        return @enumFromInt(byn.BinaryenTypeI31ref());
    }
    pub fn structref() Type {
        return @enumFromInt(byn.BinaryenTypeStructref());
    }
    pub fn arrayref() Type {
        return @enumFromInt(byn.BinaryenTypeArrayref());
    }
    pub fn stringref() Type {
        return @enumFromInt(byn.BinaryenTypeStringref());
    }
    pub fn stringviewWTF8() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewWTF8());
    }
    pub fn stringviewWTF16() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewWTF16());
    }
    pub fn stringviewIter() Type {
        return @enumFromInt(byn.BinaryenTypeStringviewIter());
    }
    pub fn nullref() Type {
        return @enumFromInt(byn.BinaryenTypeNullref());
    }
    pub fn nullExternref() Type {
        return @enumFromInt(byn.BinaryenTypeNullExternref());
    }
    pub fn nullFuncref() Type {
        return @enumFromInt(byn.BinaryenTypeNullFuncref());
    }
    pub fn unreachable_() Type {
        return @enumFromInt(byn.BinaryenTypeUnreachable());
    }

    /// Not a real type. Used as the last parameter to BinaryenBlock to let
    /// the API figure out the type instead of providing one.
    pub fn auto() Type {
        return @enumFromInt(byn.BinaryenTypeAuto());
    }

    pub fn create(value_types: []const Type) Type {
        return @enumFromInt(byn.BinaryenTypeCreate(
            @constCast(@ptrCast(value_types.ptr)),
            @intCast(value_types.len),
        ));
    }

    pub fn arity(self: Type) u32 {
        return byn.BinaryenTypeArity(@intFromEnum(self));
    }
    pub fn expand(self: Type, allocator: std.mem.Allocator) ![]Type {
        var buf = try allocator.alloc(Type, self.arity());
        byn.BinaryenTypeExpand(@intFromEnum(self), @ptrCast(buf.ptr));
        return buf;
    }
};

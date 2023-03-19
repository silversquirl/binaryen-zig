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
        return @ptrCast(*Module, mod);
    }
    pub fn deinit(self: *Module) void {
        byn.BinaryenModuleDispose(self.c());
    }

    // TODO: error handling
    pub fn parseText(wat: [*:0]const u8) *Module {
        const mod = byn.BinaryenModuleParse(wat);
        return @ptrCast(*Module, mod);
    }
    // TODO: error handling
    pub fn readBinary(wasm: []const u8) *Module {
        const mod = byn.BinaryenModuleRead(@constCast(wasm.ptr), wasm.len);
        return @ptrCast(*Module, mod);
    }

    pub fn emitText(self: *Module) [:0]u8 {
        const buf = byn.BinaryenModuleAllocateAndWriteText(self.c());
        return std.mem.span(buf);
    }
    pub fn emitBinary(self: *Module, source_map_url: ?[*:0]const u8) EmitBinaryResult {
        const result = byn.BinaryenModuleAllocateAndWrite(self.c(), source_map_url);
        return .{
            .binary = @ptrCast([*]u8, result.binary)[0..result.binaryBytes],
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
            @enumToInt(params),
            @enumToInt(results),
            @constCast(@ptrCast([*]const usize, var_types.ptr)),
            @intCast(u32, var_types.len),
            body.c(),
        );
        return @ptrCast(*Function, func);
    }

    inline fn c(self: *Module) byn.BinaryenModuleRef {
        return @ptrCast(byn.BinaryenModuleRef, self);
    }
};

pub const Expression = opaque {
    inline fn c(self: *Expression) byn.BinaryenExpressionRef {
        return @ptrCast(byn.BinaryenExpressionRef, self);
    }
};

pub const Function = opaque {
    inline fn c(self: *Function) byn.BinaryenFunctionRef {
        return @ptrCast(byn.BinaryenFunctionRef, self);
    }
};

pub const Type = enum(usize) {
    _,

    pub fn none() Type {
        return @intToEnum(Type, byn.BinaryenTypeNone());
    }
    pub fn int32() Type {
        return @intToEnum(Type, byn.BinaryenTypeInt32());
    }
    pub fn int64() Type {
        return @intToEnum(Type, byn.BinaryenTypeInt64());
    }
    pub fn float32() Type {
        return @intToEnum(Type, byn.BinaryenTypeFloat32());
    }
    pub fn float64() Type {
        return @intToEnum(Type, byn.BinaryenTypeFloat64());
    }
    pub fn vec128() Type {
        return @intToEnum(Type, byn.BinaryenTypeVec128());
    }
    pub fn funcref() Type {
        return @intToEnum(Type, byn.BinaryenTypeFuncref());
    }
    pub fn externref() Type {
        return @intToEnum(Type, byn.BinaryenTypeExternref());
    }
    pub fn anyref() Type {
        return @intToEnum(Type, byn.BinaryenTypeAnyref());
    }
    pub fn eqref() Type {
        return @intToEnum(Type, byn.BinaryenTypeEqref());
    }
    pub fn i31ref() Type {
        return @intToEnum(Type, byn.BinaryenTypeI31ref());
    }
    pub fn structref() Type {
        return @intToEnum(Type, byn.BinaryenTypeStructref());
    }
    pub fn arrayref() Type {
        return @intToEnum(Type, byn.BinaryenTypeArrayref());
    }
    pub fn stringref() Type {
        return @intToEnum(Type, byn.BinaryenTypeStringref());
    }
    pub fn stringviewWTF8() Type {
        return @intToEnum(Type, byn.BinaryenTypeStringviewWTF8());
    }
    pub fn stringviewWTF16() Type {
        return @intToEnum(Type, byn.BinaryenTypeStringviewWTF16());
    }
    pub fn stringviewIter() Type {
        return @intToEnum(Type, byn.BinaryenTypeStringviewIter());
    }
    pub fn nullref() Type {
        return @intToEnum(Type, byn.BinaryenTypeNullref());
    }
    pub fn nullExternref() Type {
        return @intToEnum(Type, byn.BinaryenTypeNullExternref());
    }
    pub fn nullFuncref() Type {
        return @intToEnum(Type, byn.BinaryenTypeNullFuncref());
    }
    pub fn unreachable_() Type {
        return @intToEnum(Type, byn.BinaryenTypeUnreachable());
    }

    /// Not a real type. Used as the last parameter to BinaryenBlock to let
    /// the API figure out the type instead of providing one.
    pub fn auto() Type {
        return @intToEnum(Type, byn.BinaryenTypeAuto());
    }

    pub fn create(value_types: []const Type) Type {
        return @intToEnum(Type, byn.BinaryenTypeCreate(
            @constCast(@ptrCast([*]const usize, value_types.ptr)),
            @intCast(u32, value_types.len),
        ));
    }

    pub fn arity(self: Type) u32 {
        return byn.BinaryenTypeArity(@enumToInt(self));
    }
    pub fn expand(self: Type, allocator: std.mem.Allocator) ![]Type {
        var buf = try allocator.alloc(Type, self.arity());
        byn.BinaryenTypeExpand(@enumToInt(self), @ptrCast([*]usize, buf.ptr));
        return buf;
    }
};

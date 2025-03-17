const std = @import("std");
const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("string.h");
});


/// CAUSES UNDEFINED / UNSAFE BEHAVIOR FOR OVERLAPPING MEMORY REGIONS\
/// MEMCPY IS WORSE THAN @memcpy AT RELEASE BUILDS
pub fn memcpy(_dst: anytype, _src: @TypeOf(_dst), size: usize) void {
    const tp = comptime @TypeOf(_dst);

    const info = comptime switch(@typeInfo(tp)) {
        .pointer => |p| p,
        else     => @compileError("Expected pointer type"),
    };
    
    const dst_ptr = if(comptime info.size == .slice) _dst.ptr else _dst;
    const src_ptr = if(comptime info.size == .slice) _src.ptr else _src;
    
    _ = c.memcpy(@alignCast(@ptrCast(dst_ptr)), @alignCast(@ptrCast(src_ptr)), size * @sizeOf(info.child));
}

/// Same as memcpy but only accepts slice pointers [*]
pub fn _memcpy(_dst: anytype, _src: @TypeOf(_dst), _size: usize) void {
    const info = comptime switch(@typeInfo(@TypeOf(_dst))) {
        .pointer => |p| p,
        else     => @compileError("Expected pointer type"),
    };
    
    _ = c.memcpy(@alignCast(@ptrCast(_dst)), @alignCast(@ptrCast(_src)), _size * @sizeOf(info.child));
}

/// SHOULD ONLY BE USED FOR STRINGS OR [ ]U8. DO NOT USE FOR U16, I16 AND ABOVE!!
/// 
/// For memset to 0 - see memset0
pub fn memset(_dst: anytype, _val: anytype, _size: usize) void {
    const tp = comptime @TypeOf(_dst);

    const info = comptime switch(@typeInfo(tp)) {
        .pointer => |p| p,
        else     => @compileError("Expected pointer type"),
    };
    if(@TypeOf(_val) != info.child)
        @compileError("Val is not the same type as array");

    _ = c.memset(@alignCast(@ptrCast(_dst)), _val, _size * @sizeOf(info.child));
}

/// EXPLICITLY FOR MEMSET TO 0
/// 
/// Ease of use instead of @as
pub fn memset0(_dst: anytype, _size: usize) void {
    const info = comptime switch(@typeInfo(@TypeOf(_dst))) {
        .pointer => |p| p,
        else     => @compileError("Expected pointer type"),
    };

    _ = c.memset(@alignCast(@ptrCast(_dst)), 0, _size * @sizeOf(info.child));
}


pub fn is_sorted(comptime T: type, arr: []T) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(arr[i] < arr[i - 1])
            return false;
            
    return true;
}

pub fn is_reverse_sorted(comptime T: type, arr: []T) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(arr[i] > arr[i - 1])
            return false;
    
    return true;
}


/// Takes a comparator function with params a, b\
/// Returns unsorted if comparator function returns true, else sorted
pub fn is_sorted_comparator(comptime T: type, arr: []T, cmp: fn(a: T, b: T) bool) bool {
    const n = arr.len;
    var i: usize = 1;
    while(i < n) : (i += 1)
        if(cmp(arr[i], arr[i - 1]))
            return false;
    
    return true;
}

pub fn notContains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |e|
        if(e == target)
            return false;
            
    return true;
}

pub fn contains(comptime T: type, arr: []T, target: T) bool {
    return !notContains(T, arr, target);
}


pub inline fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a < b) a else b;
}

pub inline fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a > b) a else b;
}

pub inline fn swap(comptime Type: type, a: *Type, b: *Type) void {
    const t = a.*;
    a.* = b.*;
    b.* = t;
}

const std = @import("std");

pub fn random() std.Random {
    var prng = std.Random.DefaultPrng.init(7);
    
    return prng.random();
}

pub inline fn cryptoRand() std.Random {
    return std.crypto.random;
}


pub inline fn free_rand_arr(allocator: std.mem.Allocator, arr: anytype) void {
    allocator.free(arr);
}

pub fn rand_int_arr_in_range(comptime T: type, allocator: std.mem.Allocator, comptime size: usize, comptime min: T, comptime max: T) []T {
    var buffer = allocator.alloc(T, size) catch @panic("but nobody came...");
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.intRangeAtMost(T, min, max);
        
    return buffer;
}

pub inline fn rand_int_arr_max(comptime T: type, allocator: std.mem.Allocator, comptime size: usize, comptime max: T) []T {
    return rand_int_arr_in_range(T, allocator, size, std.math.minInt(T), max);
}

pub inline fn rand_int_arr_min(comptime T: type, allocator: std.mem.Allocator, comptime size: usize, comptime min: T) []T {
    return rand_int_arr_in_range(T, allocator, size, min, std.math.maxInt(T));
}

pub inline fn rand_int_arr(comptime T: type, allocator: std.mem.Allocator, comptime size: usize) []T {
    return rand_int_arr_in_range(T, allocator, size, std.math.minInt(T), std.math.maxInt(T));
}

pub fn rand_i8_arr(size: usize) []i8 {
    const buffer = std.heap.smp_allocator.alloc(i8, size) catch @panic("but nobody came...");
    const rand = random();

    for(buffer) |*i|
        i.* = rand.int(i8);
        
    return buffer;
}

pub fn rand_uint_arr_max(comptime T: type, allocator: std.mem.Allocator, comptime size: usize, comptime max: T) []T {
    var buffer = allocator.alloc(T, size) catch @panic("but nobody came...");
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.uintAtMost(T, max);
        
    return buffer;
}

pub inline fn rand_uint_arr(comptime T: type, allocator: std.mem.Allocator, comptime size: usize) []T {
    return rand_uint_arr_max(T, allocator, size, std.math.maxInt(T));
}

pub fn rand_float_arr_max(comptime size: usize, allocator: std.mem.Allocator) []f64 {
    var buffer = allocator.alloc(f64, size) catch @panic("but nobody came...");
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.float(f64);
        
    return buffer;
}

pub inline fn free_i8_arr(arr: anytype) void {
    std.heap.smp_allocator.free(arr);
}

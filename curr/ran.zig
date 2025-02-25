const std = @import("std");
const allocator = std.heap.c_allocator;

pub fn random() std.Random {
    var prng = std.Random.DefaultPrng.init(7);
    
    return prng.random();
}

pub inline fn cryptRand() std.Random {
    return std.crypto.random;
}


pub fn free_rand_arr(comptime T: type, arr: []T) void {
    allocator.free(arr);
}

pub fn rand_int_arr_in_range(comptime T: type, comptime size: usize, comptime min: T, comptime max: T) []T {
    var buffer = allocator.alloc(T, size) catch unreachable;
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.intRangeAtMost(T, min, max);
        
    return buffer;
}

pub inline fn rand_int_arr_max(comptime T: type, comptime size: usize, comptime max: T) []T {
    return rand_int_arr_in_range(T, size, std.math.minInt(T), max);
}

pub inline fn rand_int_arr_min(comptime T: type, comptime size: usize, comptime min: T) []T {
    return rand_int_arr_in_range(T, size, min, std.math.maxInt(T));
}

pub inline fn rand_int_arr(comptime T: type, comptime size: usize) []T {
    return rand_int_arr_in_range(T, size, std.math.minInt(T), std.math.maxInt(T));
}

pub fn rand_uint_arr_max(comptime T: type, comptime size: usize, comptime max: T) []T {
    var buffer = allocator.alloc(T, size) catch unreachable;
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.uintAtMost(T, max);
        
    return buffer;
}

pub inline fn rand_uint_arr(comptime T: type, comptime size: usize) []T {
    return rand_uint_arr_max(T, size, std.math.maxInt(T));
}

pub fn rand_float_arr_max(comptime size: usize) []f64 {
    var buffer = allocator.alloc(f64, size) catch unreachable;
    const rand = random();

    for(0..size) |i|
        buffer[i] = rand.float(f64);
        
    return buffer;
}

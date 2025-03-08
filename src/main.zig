const std = @import("std");
const search = @import("search.zig");
const runner = @import("runner.zig");


pub var GRAPH = [_][]const u8 {
    &[_]u8 { 0,  4,  0,  12, 0,  0,  0,  0,  0,  0,  0,  0 },
    &[_]u8 { 4,  0,  8,  0,  15, 0,  0,  0,  0,  0,  0,  0 },
    &[_]u8 { 0,  8,  0,  0,  0,  10, 0,  0,  0,  0,  0,  0 },
    &[_]u8 { 12, 0,  0,  0,  2,  0,  7,  0,  0,  0,  0,  0 },
    &[_]u8 { 0,  15, 0,  2,  0,  6,  0,  9,  0,  0,  0,  0 },
    &[_]u8 { 0,  0,  10, 0,  6,  0,  0,  0,  9,  0,  0,  0 },
    &[_]u8 { 0,  0,  0,  7,  0,  0,  0,  3,  0,  5,  0,  0 },
    &[_]u8 { 0,  0,  0,  0,  9,  0,  3,  0,  0,  0,  17, 0 },
    &[_]u8 { 0,  0,  0,  0,  0,  9,  0,  0,  0,  0,  0,  14},
    &[_]u8 { 0,  0,  0,  0,  0,  0,  5,  0,  0,  0,  8,  0 },
    &[_]u8 { 0,  0,  0,  0,  0,  0,  0,  17, 0,  8,  0,  10},
    &[_]u8 { 0,  0,  0,  0,  0,  0,  0,  0,  14, 0,  10, 0 },
};


fn format(comptime T: type, path: []T) void {
    const n = path.len - 1;
    for(0..n) |i|
        std.debug.print("{} -> ", .{ path[i] + 1 });
        
    std.debug.print("{}\n", .{ path[n] + 1 });
}


pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    
    try runner.run_all_sorts_bench_with_check();
    // try runner.run_all_sorts_bench_simul();
    // try runner.run_all_sorts_bench();
}

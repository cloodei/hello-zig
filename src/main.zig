const std = @import("std");
const search = @import("DFS.zig");
const benchmark = @import("benchmark");
const sorts = @import("sorts");
const random = @import("rand");


var GRAPH = [_][]const u8 {
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
    for(0..n) |i| {
        std.debug.print("{} -> ", .{ path[i] + 1 });
    }
    std.debug.print("{}\n", .{ path[n] + 1 });
}

fn runSearchDFS(allocator: std.mem.Allocator) !void {
    const res = try search.DFS(u8, allocator, &GRAPH, 0, 11);
    allocator.free(res);
}


var arr: []i32 = undefined;

fn runMS(_: std.mem.Allocator, timer: *std.time.Timer) !void {
    arr = random.rand_int_arr_in_range(i32, 1_000_000, 0, 1_048_576);
    defer random.free_rand_arr(i32, arr);

    std.debug.print("{}\n", .{
        sorts.is_sorted(i32, arr)
    });

    timer.reset();
    sorts.mergeSort(i32, arr);
}

pub fn main() !void {
    // var y = try benchmark.run(runSearchDFS);
    // y.print("Search DFS");

    // sorts.mergeSort(i32, arr);
    // sorts.quickSort(i32, arr);
    // sorts.heapSort (i32, arr);

    var x = try benchmark.run(void, runMS);
    x.print("MergeSort");
    std.debug.print("{}\n", .{ sorts.is_sorted(i32, arr) });
}

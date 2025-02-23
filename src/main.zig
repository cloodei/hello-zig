const std = @import("std");
const Stack = @import("stack").Stack;
const search = @import("DFS.zig");

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


fn format(comptime T: type, arr: []T) void {
    const n = arr.len - 1;
    for(0..n) |i| {
        std.debug.print("{} -> ", .{ arr[i] + 1 });
    }
    std.debug.print("{}\n", .{ arr[n] + 1 });
}

pub fn main() !void {
    const thing = try search.DFS(u8, &GRAPH, 0, 11);
    defer search.freePath(usize, thing);
    format(usize, thing);
}

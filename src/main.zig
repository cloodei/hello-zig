const std = @import("std");
const Stack = @import("stack").Stack;
const search = @import("DFS.zig");
const benchmark = @import("benchmark");


fn contains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |val|
        if(val == target)
            return true;
            
    return false;
}

fn DFS(comptime T: type, allocator: std.mem.Allocator, matrix: [][]const T, comptime start: usize, comptime end: usize) ![]usize {
    var open = std.ArrayList([]usize).init(allocator);
    defer {
        for(open.items) |path| {
            allocator.free(path);
        }
        open.deinit();
    }

    var initial_path = try allocator.alloc(usize, 1);
    initial_path[0] = start;
    try open.append(initial_path);

    while(open.items.len != 0) {
        const current_path = open.pop();
        defer allocator.free(current_path);

        const len = current_path.len;
        const current_node = current_path[len - 1];

        if(current_node == end) {
            const result = try allocator.dupe(usize, current_path);
            return result;
        }

        var i = matrix.len;
        while(i != 0) : (i -= 1) {
            const nb = i - 1;
            if(matrix[current_node][nb] != 0) {
                if(!contains(usize, current_path, nb)) {
                    var new = try allocator.alloc(usize, len + 1);
                    errdefer allocator.free(new);

                    @memcpy(new[0..len], current_path);
                    new[len] = nb;

                    try open.append(new);
                }
            }
        }
    }

    return &[_]usize {};
}

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

fn runDFS(allocator: std.mem.Allocator) !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    const res = try DFS(u8, allocator, &GRAPH, 0, 11);
    allocator.free(res);
}

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    // const path = try DFS(u8, allocator, &GRAPH, 0, 11);
    // defer allocator.free(path);
    // format(usize, path);

    var x = try benchmark.run(runDFS);
    x.print("DFS");
}

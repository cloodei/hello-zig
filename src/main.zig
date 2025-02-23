const std = @import("std");
const Stack = @import("stack").Stack;

const GRAPH = [_][]const u8 {
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


/// Leaking memory profusely?\
/// Needs further revision
fn DFS(comptime start: usize, comptime end: usize) ![]usize {
    var open = Stack([]usize).init(64); // Stack is leaking memory, segfault a lot?
    const allocator = open.allocator;
    defer {
        for(open.arr[0..open.len]) |arr| {
            allocator.free(arr);
        }
        open.deinit();
    }

    const tmp = try allocator.alloc(usize, 1);
    tmp[0] = start;
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        const len = path.len;
        const curr = path[len - 1];

        if(curr == end) {
            const ret = try allocator.alloc(usize, len);
            @memcpy(ret, path);
            return ret;
        }

        for(GRAPH[curr], 0..) |adj, nb| {
            if(adj != 0) {
                const newPath = try allocator.alloc(usize, len + 1);
                @memcpy(newPath[0..len], path);
                newPath[len] = nb;
                open.push(newPath);
            }
        }

        allocator.free(path);
    }

    return &[_]usize {};
}

fn format(comptime T: type, arr: []T) void {
    const n = arr.len - 1;
    for(0..n) |i| {
        std.debug.print("{} -> ", .{ arr[i] });
    }
    std.debug.print("{}\n", .{ arr[n] });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const thing = try DFS(0, 11);
    defer allocator.free(thing);

    format(usize, thing);
}

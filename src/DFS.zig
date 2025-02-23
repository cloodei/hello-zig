const std = @import("std");
const Stack = @import("stack").Stack;
const Queue = @import("buffer");


fn notContains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |e|
        if(e == target)
            return false;
            
    return true;
}

pub fn DFS(comptime T: type, GRAPH: [][]const T, comptime start: usize, comptime end: usize) ![]usize {
    var open = Stack([]usize).init(32);
    const allocator = open.allocator;
    defer {
        for(open.arr[0..open.len]) |arr| {
            allocator.free(arr);
        }
        open.deinit();
    }

    var tmp = try allocator.alloc(usize, 1);
    std.debug.print("{any}\n", .{ tmp });
    tmp[0] = start;
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        defer allocator.free(path);

        const len = path.len;
        const curr = path[len - 1];

        if(curr == end) {
            const ret = try allocator.alloc(usize, len);
            @memcpy(ret, path);
            return ret;
        }

        for(GRAPH[curr], 0..) |adj, nb| {
            if(adj != 0) {
                if(notContains(usize, path, nb)) {
                    const newPath = try allocator.alloc(usize, len + 1);
                    @memcpy(newPath[0..len], path);
                    newPath[len] = nb;
                    open.push(newPath);
                }
            }
        }
    }

    return &[_]usize {};
}


pub fn freePath(comptime T: type, mem: []T) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    allocator.free(mem);
}

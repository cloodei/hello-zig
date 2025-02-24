const std = @import("std");
const Stack = @import("stack").Stack;
const Queue = @import("buffer");


fn notContains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |e|
        if(e == target)
            return false;
            
    return true;
}

pub fn DFS(comptime T: type, allocator: std.mem.Allocator, GRAPH: [][]const T, start: usize, end: usize) !?[]usize {
    var open = Stack([]usize).init(16);
    defer {
        // for(0..open.len) |i| {
        //     open.allocator.free(open.arr[i]);
        // }
        open.deinit();
    }

    var tmp = try open.allocator.alloc(usize, 1);
    // errdefer open.allocator.free(tmp);
    tmp[0] = start;
    std.debug.print("{any}", .{ tmp });
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        const len = path.len;
        const curr = path[len - 1];

        if(curr == end) {
            const ret = try allocator.alloc(usize, len);
            @memcpy(ret, path);
            // open.allocator.free(path);
            return ret;
        }

        for(GRAPH[curr], 0..) |adj, nb| {
            if(adj != 0) {
                if(notContains(usize, path, nb)) {
                    const newPath = try open.allocator.alloc(usize, len + 1);
                    @memcpy(newPath[0..len], path);
                    newPath[len] = nb;
                    open.push(newPath);
                }
            }
        }
        // open.allocator.free(path);
    }

    return null;
}


pub fn freePath(comptime T: type, mem: []T) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    allocator.free(mem);
}

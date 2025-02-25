const std = @import("std");
const Stack = @import("stack").Stack;
const Queue = @import("buffer");


fn notContains(comptime T: type, arr: []T, target: T) bool {
    for(arr) |e|
        if(e == target)
            return false;
            
    return true;
}

pub fn DFS(T: type, allocator: std.mem.Allocator, GRAPH: [][]const T, comptime start: usize, comptime end: usize) ![]usize {
    var open = Stack([]usize).init(allocator, 16);
    defer {
        for(open.items[0..open.len]) |item| {
            allocator.free(item);
        }
        open.deinit();
    }

    var tmp = try allocator.alloc(usize, 1);
    tmp[0] = start;
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        const len = path.len;
        const curr = path[len - 1];

        if(curr == end) {
            return path;
        }

        var i: usize = GRAPH.len;
        while(i != 0) : (i -= 1) {
            const nb = i - 1;
            if(GRAPH[curr][nb] != 0) {
                if(notContains(usize, path, nb)) {
                    const newPath = try allocator.alloc(usize, len + 1);
                    @memcpy(newPath[0..len], path);
                    newPath[len] = nb;
                    open.push(newPath);
                }
            }
        }

        allocator.free(path);
    }

    return &[_]usize {};
}


pub fn freePath(comptime T: type, mem: []T) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    allocator.free(mem);
}

const std = @import("std");
const Queue = @import("queue").Queue;
const notContains = @import("utils").notContains;

pub fn BFS(comptime T: type, allocator: std.mem.Allocator, GRAPH: [][]const T, comptime start: usize, comptime finish: usize) ![]usize {
    var open = Queue([]usize).init(allocator, 16);
    defer {
        if(open.front < open.back) {
            for(open.items[open.front..open.back]) |thing| {
                allocator.free(thing);
            }
        }
        else {
            for(open.items[open.front..open.capacity()]) |thing| {
                allocator.free(thing);
            }
            for(open.items[0..open.back]) |thing| {
                allocator.free(thing);
            }
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

        if(curr == finish)
            return path;
        
        for(GRAPH[curr], 0..) |adj, nb| {
            if(adj != 0) {
                if(notContains(usize, path, nb)) {
                    const new = try allocator.alloc(usize, len + 1);
                    @memcpy(new.ptr, path);
                    new[len] = nb;
                    open.push(new);
                }
            }
        }

        allocator.free(path);
    }

    return &[_]usize {};
}

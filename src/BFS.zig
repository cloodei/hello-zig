const std = @import("std");
const Queue = @import("queue").Queue;


/// TODO: Revisit tomorrow :)
pub fn BFS(comptime T: type, _: [][]const T, comptime _: usize, comptime _: usize) []usize {
    var open = Queue([]usize).init(16);
    const allocator = open.allocator;
    defer {
        for(open.arr) |thing| {
            allocator.free(thing);
        }
        open.deinit();
    }

    while(open.len != 0) {
        const path = open.pop();
        defer allocator.free(path);
    }
}

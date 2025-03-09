const std = @import("std");
const Queue = @import("queue").Queue;
const Stack = @import("stack").Stack;
const notContains = @import("utils").notContains;


pub const GRAPH = [_][]const u8 {
    &[_]u8 { 0,  4,  0,  12, 0,  0,  0,  0,  0,  0,  0,  0 },   // 1
    &[_]u8 { 4,  0,  8,  0,  15, 0,  0,  0,  0,  0,  0,  0 },   // 2
    &[_]u8 { 0,  8,  0,  0,  0,  10, 0,  0,  0,  0,  0,  0 },   // 3
    &[_]u8 { 12, 0,  0,  0,  2,  0,  7,  0,  0,  0,  0,  0 },   // 4
    &[_]u8 { 0,  15, 0,  2,  0,  6,  0,  9,  0,  0,  0,  0 },   // 5
    &[_]u8 { 0,  0,  10, 0,  6,  0,  0,  0,  9,  0,  0,  0 },   // 6
    &[_]u8 { 0,  0,  0,  7,  0,  0,  0,  3,  0,  5,  0,  0 },   // 7
    &[_]u8 { 0,  0,  0,  0,  9,  0,  3,  0,  0,  0,  17, 0 },   // 8
    &[_]u8 { 0,  0,  0,  0,  0,  9,  0,  0,  0,  0,  0,  14},   // 9
    &[_]u8 { 0,  0,  0,  0,  0,  0,  5,  0,  0,  0,  8,  0 },   // 10
    &[_]u8 { 0,  0,  0,  0,  0,  0,  0,  17, 0,  8,  0,  10},   // 11
    &[_]u8 { 0,  0,  0,  0,  0,  0,  0,  0,  14, 0,  10, 0 },   // 12
};
//                                     1   2   3   4   5   6   7   8   9  10  11  12
pub const HEURISTICS = [_]u8 { 0,  7,  4, 12, 10, 15,  6,  8, 11,  6, 10,  1 };


pub fn BFS(allocator: std.mem.Allocator, comptime start: usize, comptime end: usize) ![]usize {
    var open = Queue([]usize).init(allocator, 32);
    defer {
        if(open.front < open.back) {
            for(open.items[open.front..open.back]) |thing|
                allocator.free(thing);
        }
        else {
            for(open.items[open.front..open.capacity()]) |thing|
                allocator.free(thing);
                
            for(open.items[0..open.back]) |thing|
                allocator.free(thing);
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

        if(curr == end)
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


pub fn DFS(allocator: std.mem.Allocator, comptime start: usize, comptime end: usize) ![]usize {
    var open = Stack([]usize).init(allocator, 16);
    defer {
        for(open.arr()) |mem|
            allocator.free(mem);
            
        open.deinit();
    }

    var tmp = try allocator.alloc(usize, 1);
    tmp[0] = start;
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        const len = path.len;
        const curr = path[len - 1];

        if(curr == end)
            return path;

        var i: usize = GRAPH.len;
        while(i != 0) : (i -= 1) {
            const nb = i - 1;
            if(GRAPH[curr][nb] != 0) {
                if(notContains(usize, path, nb)) {
                    const newPath = try allocator.alloc(usize, len + 1);
                    @memcpy(newPath.ptr, path);
                    newPath[len] = nb;
                    open.push(newPath);
                }
            }
        }

        allocator.free(path);
    }

    return &[_]usize {};
}


pub fn HCS(allocator: std.mem.Allocator, comptime start: usize, comptime end: usize) ![]usize {
    var open = Stack([]usize).init(allocator, 16);
    defer {
        for(open.arr()) |thing| {
            allocator.free(thing);
        }
        open.deinit();
    }

    const cmp = comptime struct {
        fn cmp(a: usize, b: usize) bool {
            return HEURISTICS[a] > HEURISTICS[b];
        }
    }.cmp;

    var tmp = try allocator.alloc(usize, 1);
    tmp[0] = start;
    open.push(tmp);

    while(open.len != 0) {
        const path = open.pop();
        const len = path.len;
        const curr = path[len - 1];

        if(curr == end)
            return path;

        var adjs = Stack(usize).init(allocator, GRAPH.len);
        defer adjs.deinit();

        for(GRAPH[curr], 0..) |adj, nb|
            if(adj != 0)
                if(notContains(usize, path, nb))
                    adjs.push(nb);
        
        adjs.sortSpec(cmp);

        for(adjs.arr()) |adj| {
            var new = try allocator.alloc(usize, len + 1);
            @memcpy(new.ptr, path);
            new[len] = adj;
            open.push(new);
        }

        allocator.free(path);
    }

    return &[_]usize {};
}


// pub fn BSS(allocator: std.mem.Allocator, comptime start: usize, comptime end: usize) ![]usize {
//     var open = Stack([]usize).init(allocator, 16);
// }

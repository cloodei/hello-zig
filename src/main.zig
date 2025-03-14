const std = @import("std");
const search = @import("search.zig");
const runner = @import("runner.zig");
const Stack = @import("stack").Stack;
const String = @import("string");


pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{}).init;
    defer _ = dba.deinit();
    const allocator = dba.allocator();

    const thing = try allocator.alloc(i32, 8);
    defer allocator.free(thing);
    @memset(thing, 32);
    const another: isize = -1;
    std.debug.print("{}", .{ thing[another] });

    // var path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.DFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    
    // try runner.run_all_sorts_bench_with_check(false);
    // try runner.run_all_sorts_bench_simul(false);
    // try runner.run_all_sorts_bench(false);

    // try runner.run_memcpys_bench(true);
    // try runner.run_memsets_bench(true);

    // try runner.run_all_search(false);
}

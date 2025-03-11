const std = @import("std");
const search = @import("search.zig");
const runner = @import("runner.zig");
const Stack = @import("stack").Stack;


pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    // const path = try search.HCS(allocator, 0, 11);
    // defer allocator.free(path);
    // format(usize, path);
    
    // try runner.run_all_sorts_bench_with_check(false);
    // try runner.run_all_sorts_bench_simul(false);
    try runner.run_all_sorts_bench(false);

    // try runner.run_memcpys_bench(true);

    // try runner.run_all_search(false);
}

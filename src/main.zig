const std = @import("std");
const search = @import("search.zig");
const runner = @import("runner.zig");
const Stack = @import("stack").Stack;


fn format(comptime T: type, path: []T) void {
    const n = path.len - 1;
    for(0..n) |i|
        std.debug.print("{} -> ", .{ path[i] + 1 });
        
    std.debug.print("{}\n", .{ path[n] + 1 });
}


pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    // const path = try search.HCS(allocator, 0, 11);
    // defer allocator.free(path);
    // format(usize, path);
    
    // try runner.run_all_sorts_bench_with_check(false);
    // try runner.run_all_sorts_bench_simul(false);
    // try runner.run_all_sorts_bench(false);

    // try runner.run_memcpys_bench(true);

    try runner.run_all_search(false);
    
    // Liên hệ hỗ trợ, Quản lý giỏ hàng và Hậu mãi của actor Người dùng;
}

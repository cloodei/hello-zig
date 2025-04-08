const std = @import("std");
const env = @import("env.zig");
const rand = @import("rand");
const utils = @import("utils");
const sorts = @import("sorts");
const String = @import("string");
const search = @import("search.zig");
const runner = @import("runner.zig");
const contest = @import("vnoi.zig");
const Stack = @import("stack").Stack;

const time = std.time;
// const SIZE = 10_485_760; // 10 MB x 4
// const SIZE = 52_428_800; // 50 MB x 4
const SIZE = 104_857_600; // 100 MB x 4
// const SIZE = 268_435_456; // 256 MB x 4

fn check(dst: anytype, src: anytype) bool {
    return std.mem.eql(i32, src, dst);
}

fn checkSorted(comptime T: type, former: []T, latter: []T) bool {
    const n = latter.len;
    if(former.len != n)
        return false;
    if(former.len == 0)
        return true;

    var i: usize = 1;
    while(i < n) : (i += 1)
        if(latter[i] < latter[i - 1])
            return false;

    const allocator = std.heap.smp_allocator;
    const orig = allocator.alloc(T, n) catch unreachable;
    defer allocator.free(orig);
    @memcpy(orig.ptr, former);

    std.sort.pdq(T, orig, {}, std.sort.asc(T));

    for(orig, latter) |a, b|
        if(a != b)
            return false;

    return true;
}

pub fn main() !void {
    // try contest.m26a();
    // try contest.cpp_ptit_41();

    var dba = std.heap.DebugAllocator(.{}).init;
    defer _ = dba.deinit();
    const allocator = dba.allocator();

    // const arr = rand.rand_i8_arr(25);
    // defer rand.free_i8_arr(arr);
    // const copy = try allocator.alloc(i8, arr.len);
    // defer allocator.free(copy);
    // @memcpy(copy, arr.ptr);
    // std.debug.print("Arr: {any}\n", .{ arr });
    // sorts.radixSort(i8, arr);
    // std.debug.print("Arr: {any}\nSorted: {}\n", .{ arr, checkSorted(i8, copy, arr) });

    // try runner.run_radsort_bench_with_check(true);
    // try runner.run_radsort_bench(false);
    // try runner.run_all_sorts_bench_with_check(true);
    // try runner.run_all_sorts_bench(false);

    // var t = try String.read_int_endl(usize, thing);
    // var vec = Stack(i32).init(allocator, 100);
    // defer vec.deinit();

    // while(t != 0) : (t -= 1) {
    //     const n = try String.read_int_endl(usize, thing) - 1;
    //     for(0..n) |_| {
    //         vec.pushAssumeCap(try String.read_int(i32, thing));
    //     }
    //     vec.pushAssumeCap(try String.read_int_endl(i32, thing));
    //     vec.sort();
    //     std.debug.print("{}\n", .{ vec.items[vec.len - 2] - vec.items[0] });
    //     vec.len = 0;
    // }

    // var start = time.nanoTimestamp();
    // const stdp = try std.fmt.parseInt(i128, some, 10);
    // var end = time.nanoTimestamp();
    // const stdTime = @as(f64, @floatFromInt(end - start)) / 1000.0;

    // start = time.nanoTimestamp();
    // const cusp = String.str_parse_int(some).?;
    // end = time.nanoTimestamp();
    // const cusTime = @as(f64, @floatFromInt(end - start)) / 1000.0;

    // std.debug.print("STD: {d} | {d} us\nCUS: {d} | {d} us", .{
    //     stdp, stdTime,
    //     cusp, cusTime
    // });

    // var vec = Stack([]const u8).initAllocator(allocator);
    // defer vec.deinit();
    // var vec2 = Stack(u8).initAllocator(allocator);
    // defer vec2.deinit();

    // try vec.push("the phone rings");
    // try vec.push("...");
    // try vec.push("but nobody came");

    // try vec2.push(32);
    // try vec2.push(31);
    // try vec2.push(232);
    // try vec2.push(132);
    // try vec2.push(99);

    // std.debug.print("{}\n", .{ vec });
    // std.debug.print("{}\n", .{ vec2 });

    const src = rand.rand_int_arr_min(i32, allocator, SIZE, 1);
    const dst1 = try allocator.alloc(i32, SIZE);

    var start = time.microTimestamp();
    utils._memcpy(dst1.ptr, src.ptr, SIZE);
    var end = time.microTimestamp();
    const memcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    const memcpyCheck = check(dst1, src);
    @memset(dst1, 0);

    start = time.microTimestamp();
    @memcpy(dst1.ptr, src);
    end = time.microTimestamp();
    const stdcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    const stdcpyCheck = check(dst1, src);
    @memset(dst1, 0);

    start = time.microTimestamp();
    var i: usize = 0;
    while(i != dst1.len) : (i += 1)
        dst1[i] = src[i];
    end = time.microTimestamp();
    const forcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    const forcpyCheck = check(dst1, src);

    allocator.free(src);
    allocator.free(dst1);

    std.debug.print("Memcpy    : {d} ms | {}\nZig memcpy: {d} ms | {}\nFor memcpy: {d} ms | {}\n", .{
        memcpyTime, memcpyCheck,
        stdcpyTime, stdcpyCheck,
        forcpyTime, forcpyCheck,
    });

    // var path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.DFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);

    // try runner.run_all_sorts_bench_with_check(true);
    // try runner.run_all_sorts_bench_simul(false);
    // try runner.run_all_sorts_bench(false);

    // try runner.run_memcpys_bench(false);
    // try runner.run_memsets_bench(false);

    // try runner.run_all_search(false);
}

const std = @import("std");
const env = @import("env.zig");
const rand = @import("rand");
const utils = @import("utils");
const String = @import("string");
const search = @import("search.zig");
const runner = @import("runner.zig");
const Stack = @import("stack").Stack;

const time = std.time;
// const SIZE = 268_435_456; // 256 MB x 4
const SIZE = 10_485_760; // 10 MB x 4

fn check(dst: anytype, src: anytype) bool {
    for(0..src.len) |i|
        if(src[i] != dst[i])
            return false;

    return true;
}


pub fn main() !void {
    var dba = std.heap.DebugAllocator(.{}).init;
    defer _ = dba.deinit();
    const allocator = dba.allocator();

    const thing = try allocator.alloc(u8, 32);
    defer allocator.free(thing);

    // const cwd = std.fs.cwd();
    // const stuff = try cwd.readFile("src/data.json", thing);
    // // const some = try std.json.parseFromSlice(struct {}, allocator, stuff, .{});
    // std.debug.print("{s}\n{d}", .{ stuff, stuff.len });

    const stdin = std.io.getStdIn().reader();
    const some = (try stdin.readUntilDelimiter(thing, '\r'));

    var start = time.nanoTimestamp();
    const stdp = try std.fmt.parseInt(i128, some, 10);
    var end = time.nanoTimestamp();
    const stdTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    

    start = time.nanoTimestamp();
    const cusp = String.str_parse_int(some).?;
    end = time.nanoTimestamp();
    const cusTime = @as(f64, @floatFromInt(end - start)) / 1000.0;

    std.debug.print("STD: {d} | {d} us\nCUS: {d} | {d} us", .{
        stdp, stdTime,
        cusp, cusTime
    });


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

    // const src = rand.rand_int_arr_min(i32, allocator, SIZE, 1);
    // defer rand.free_rand_arr(allocator, src);

    // const dst1 = try allocator.alloc(i32, SIZE);
    // var start = time.microTimestamp();
    // utils._memcpy(dst1.ptr, src.ptr, SIZE);
    // var end = time.microTimestamp();
    // const memcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const memcpyCheck = check(dst1, src);
    // allocator.free(dst1);

    // const dst2 = try allocator.alloc(i32, SIZE);
    // start = time.microTimestamp();
    // @memcpy(dst2.ptr, src);
    // end = time.microTimestamp();
    // const stdcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const stdcpyCheck = check(dst2, src);
    // allocator.free(dst2);

    // const dst3 = try allocator.alloc(i32, SIZE);
    // start = time.microTimestamp();
    // var i: usize = 0;
    // while(i != dst3.len) : (i += 1)
    //     dst3[i] = src[i];
    // end = time.microTimestamp();
    // const forcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const forcpyCheck = check(dst3, src);
    // allocator.free(dst3);

    // std.debug.print("Memcpy    : {d} ms | {}\nZig memcpy: {d} ms | {}\nFor memcpy: {d} ms | {}\n", .{
    //     memcpyTime, memcpyCheck,
    //     stdcpyTime, stdcpyCheck,
    //     forcpyTime, forcpyCheck,
    // });

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

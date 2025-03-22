const std = @import("std");
const search = @import("search.zig");
const random = @import("rand");
const sorts = @import("sorts");
const utils = @import("utils");
const benchmark = @import("benchmark");

const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;


pub fn forlcpy(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);
    const buffer = try allocator.alloc(i32, arr.len);
    defer allocator.free(buffer);

    var i: usize = 0;
    timer.reset();
    while(i < arr.len) : (i += 1)
        buffer[i] = arr[i];
}

pub fn cmemcpy(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);
    const buffer = try allocator.alloc(i32, arr.len);
    defer allocator.free(buffer);

    timer.reset();
    utils._memcpy(buffer.ptr, arr.ptr, arr.len);
}

pub fn stdmemcpy(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);
    const buffer = try allocator.alloc(i32, arr.len);
    defer allocator.free(buffer);

    timer.reset();
    @memcpy(buffer, arr);
}

pub fn run_forlcpy_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(forlcpy, use_dba);
    x.print("For Memcpy");
}

pub fn run_cmemcpy_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(cmemcpy, use_dba);
    x.print("C Memcpy");
}

pub fn run_stdmemcpy_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(stdmemcpy, use_dba);
    x.print("Zig Memcpy");
}

pub fn run_memcpys_bench(comptime use_dba: bool) !void {
    try run_forlcpy_bench(use_dba);
    try run_cmemcpy_bench(use_dba);
    try run_stdmemcpy_bench(use_dba);
}


pub fn forlset(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);

    var i: usize = 0;
    timer.reset();
    while(i < arr.len) : (i += 1)
        arr[i] = 0;
}

pub fn cmemset(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);

    timer.reset();
    utils.memset0(arr.ptr, 120_000_000);
}

pub fn stdmemset(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 120_000_000, 0, 750_000_000);
    defer allocator.free(arr);

    timer.reset();
    @memset(arr, 0);
}

pub fn run_forlset_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(forlset, use_dba);
    x.print("For Memset");
}

pub fn run_cmemset_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(cmemset, use_dba);
    x.print("C Memset");
}

pub fn run_stdmemset_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(stdmemset, use_dba);
    x.print("Zig Memset");
}

pub fn run_memsets_bench(comptime use_dba: bool) !void {
    try run_forlset_bench(use_dba);
    try run_cmemset_bench(use_dba);
    try run_stdmemset_bench(use_dba);
}

pub fn runSearchDFS(allocator: Allocator, _: *Timer) !void {
    const res = try search.DFS(allocator, 0, 11);
    allocator.free(res);
}

pub fn runSearchBFS(allocator: Allocator, _: *Timer) !void {
    const res = try search.BFS(allocator, 0, 11);
    allocator.free(res);
}

pub fn runSearchHCS(allocator: Allocator, _: *Timer) !void {
    const res = try search.HCS(allocator, 0, 11);
    allocator.free(res);
}

pub fn run_DFS_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runSearchDFS, use_dba);
    x.print("DFS");
}

pub fn run_BFS_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runSearchBFS, use_dba);
    x.print("BFS");
}

pub fn run_HCS_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runSearchHCS, use_dba);
    x.print("HCS");
}

pub fn run_all_search(comptime use_dba: bool) !void {
    try run_DFS_bench(use_dba);
    try run_BFS_bench(use_dba);
    try run_HCS_bench(use_dba);
}

pub fn run_all_search_simul(comptime use_dba: bool) !void {
    const t1 = try std.Thread.spawn(.{}, run_DFS_bench, .{ use_dba });
    const t2 = try std.Thread.spawn(.{}, run_BFS_bench, .{ use_dba });
    const t3 = try std.Thread.spawn(.{}, run_HCS_bench, .{ use_dba });

    t1.join();
    t2.join();
    t3.join();
}

pub fn runCheckMS(allocator: Allocator, timer: *Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.mergeSort(i32, arr);
    return arr;
}

pub fn runCheckHS(allocator: Allocator, timer: *Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.heapSort(i32, arr);
    return arr;
}

pub fn runCheckQS(allocator: Allocator, timer: *Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.quickSort(i32, arr);
    return arr;
}

pub fn runCheckSS(allocator: Allocator, timer: *Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    std.mem.sort(i32, arr, {}, std.sort.asc(i32));
    return arr;
}

pub fn runQS(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(allocator, arr);

    timer.reset();
    sorts.quickSort(i32, arr);
}

pub fn runHS(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(allocator, arr);

    timer.reset();
    sorts.heapSort(i32, arr);
}

pub fn runMS(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(allocator, arr);

    timer.reset();
    sorts.mergeSort(i32, arr);
}

pub fn runSS(allocator: Allocator, timer: *Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(allocator, arr);

    timer.reset();
    std.mem.sort(i32, arr, {}, std.sort.asc(i32));
}

pub fn run_mergesort_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runMS, use_dba);
    x.print("MergeSort");
}
pub fn run_quicksort_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runQS, use_dba);
    x.print("QuickSort");
}
pub fn run_heapsort_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runHS, use_dba);
    x.print("HeapSort");
}
pub fn run_stdsort_bench(comptime use_dba: bool) !void {
    var x = try benchmark.run(runSS, use_dba);
    x.print("STD Sort");
}

pub fn checkSorted(array: []i32) !void {
    std.debug.print("Sorted: {}\n", .{ utils.is_sorted(i32, array) });
}

pub fn run_mergesort_bench_with_check(comptime use_dba: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckMS, checkSorted, use_dba);
    x.print("MergeSort");
}
pub fn run_quicksort_bench_with_check(comptime use_dba: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckQS, checkSorted, use_dba);
    x.print("QuickSort");
}
pub fn run_heapsort_bench_with_check(comptime use_dba: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckHS, checkSorted, use_dba);
    x.print("HeapSort");
}
pub fn run_stdsort_bench_with_check(comptime use_dba: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckSS, checkSorted, use_dba);
    x.print("STD Sort");
}

pub fn run_all_sorts_bench(comptime use_dba: bool) !void {
    try run_mergesort_bench(use_dba);
    try run_quicksort_bench(use_dba);
    try run_stdsort_bench(use_dba);
    try run_heapsort_bench(use_dba);
}

pub fn run_all_sorts_bench_with_check(comptime use_dba: bool) !void {
    try run_mergesort_bench_with_check(use_dba);
    try run_quicksort_bench_with_check(use_dba);
    try run_stdsort_bench_with_check(use_dba);
    try run_heapsort_bench_with_check(use_dba);
}

pub fn run_all_sorts_bench_simul(comptime use_dba: bool) !void {
    var t1 = try std.Thread.spawn(.{}, run_mergesort_bench, .{ use_dba });
    var t2 = try std.Thread.spawn(.{}, run_quicksort_bench, .{ use_dba });
    var t3 = try std.Thread.spawn(.{}, run_heapsort_bench, .{ use_dba });
    var t4 = try std.Thread.spawn(.{}, run_stdsort_bench, .{ use_dba });

    t1.join();
    t2.join();
    t3.join();
    t4.join();
}

pub fn run_all_sorts_bench_with_check_simul(comptime use_dba: bool) !void {
    var t1 = try std.Thread.spawn(.{}, run_mergesort_bench_with_check, .{ use_dba });
    var t2 = try std.Thread.spawn(.{}, run_quicksort_bench_with_check, .{ use_dba });
    var t4 = try std.Thread.spawn(.{}, run_heapsort_bench_with_check, .{ use_dba });
    var t3 = try std.Thread.spawn(.{}, run_stdsort_bench_with_check, .{ use_dba });

    t1.join();
    t2.join();
    t3.join();
    t4.join();
}

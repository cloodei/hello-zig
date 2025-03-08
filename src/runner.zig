const std = @import("std");
const search = @import("search.zig");
const random = @import("rand");
const sorts = @import("sorts");
const utils = @import("utils");
const benchmark = @import("benchmark");
const GRAPH = @import("root").GRAPH;


pub fn runSearchDFS(allocator: std.mem.Allocator, _: *std.time.Timer) !void {
    const res = try search.DFS(u8, allocator, &GRAPH, 0, 11);
    allocator.free(res);
}

pub fn runSearchBFS(allocator: std.mem.Allocator, _: *std.time.Timer) !void {
    const res = try search.BFS(u8, allocator, &GRAPH, 0, 11);
    allocator.free(res);
}


pub fn runCheckMS(allocator: std.mem.Allocator, timer: *std.time.Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.mergeSort(i32, arr);
    return arr;
}

pub fn runCheckHS(allocator: std.mem.Allocator, timer: *std.time.Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.heapSort(i32, arr);
    return arr;
}

pub fn runCheckQS(allocator: std.mem.Allocator, timer: *std.time.Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    sorts.quickSort(i32, arr);
    return arr;
}

pub fn runCheckSS(allocator: std.mem.Allocator, timer: *std.time.Timer) ![]i32 {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);

    timer.reset();
    std.mem.sort(i32, arr, {}, std.sort.asc(i32));
    return arr;
}

pub fn runQS(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(i32, allocator, arr);

    timer.reset();
    sorts.quickSort(i32, arr);
}

pub fn runHS(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(i32, allocator, arr);

    timer.reset();
    sorts.heapSort(i32, arr);
}

pub fn runMS(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(i32, allocator, arr);

    timer.reset();
    sorts.mergeSort(i32, arr);
}

pub fn runSS(allocator: std.mem.Allocator, timer: *std.time.Timer) !void {
    const arr = random.rand_int_arr_in_range(i32, allocator, 1_000_000, 0, 4_194_304);
    defer random.free_rand_arr(i32, allocator, arr);

    timer.reset();
    std.mem.sort(i32, arr, {}, std.sort.asc(i32));
}


pub fn run_mergesort_bench(comptime use_gpa: bool) !void {
    var x = try benchmark.run(runMS, use_gpa);
    x.print("MergeSort");
}
pub fn run_quicksort_bench(comptime use_gpa: bool) !void {
    var x = try benchmark.run(runQS, use_gpa);
    x.print("QuickSort");
}
pub fn run_heapsort_bench(comptime use_gpa: bool) !void {
    var x = try benchmark.run(runHS, use_gpa);
    x.print("HeapSort");
}
pub fn run_stdsort_bench(comptime use_gpa: bool) !void {
    var x = try benchmark.run(runSS, use_gpa);
    x.print("STD Sort");
}


pub fn check(array: []i32) !void {
    std.debug.print("Sorted: {}\n", .{ utils.is_sorted(i32, array) });
}

pub fn run_mergesort_bench_with_check(comptime use_gpa: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckMS, check, use_gpa);
    x.print("MergeSort");
}
pub fn run_quicksort_bench_with_check(comptime use_gpa: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckQS, check, use_gpa);
    x.print("QuickSort");
}
pub fn run_heapsort_bench_with_check(comptime use_gpa: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckHS, check, use_gpa);
    x.print("HeapSort");
}
pub fn run_stdsort_bench_with_check(comptime use_gpa: bool) !void {
    var x = try benchmark.runWithReturn([]i32, runCheckSS, check, use_gpa);
    x.print("STD Sort");
}


pub fn run_all_sorts_bench(comptime use_gpa: bool) !void {
    try run_mergesort_bench(use_gpa);
    try run_quicksort_bench(use_gpa);
    try run_stdsort_bench(use_gpa);
    try run_heapsort_bench(use_gpa);
}

pub fn run_all_sorts_bench_with_check(comptime use_gpa: bool) !void {
    try run_mergesort_bench_with_check(use_gpa);
    try run_quicksort_bench_with_check(use_gpa);
    try run_stdsort_bench_with_check(use_gpa);
    try run_heapsort_bench_with_check(use_gpa);
}


pub fn run_all_sorts_bench_simul(comptime use_gpa: bool) !void {
    var t1 = try std.Thread.spawn(.{}, run_mergesort_bench, .{ use_gpa });
    var t2 = try std.Thread.spawn(.{}, run_quicksort_bench, .{ use_gpa });
    var t3 = try std.Thread.spawn(.{}, run_heapsort_bench,  .{ use_gpa });
    var t4 = try std.Thread.spawn(.{}, run_stdsort_bench,   .{ use_gpa });

    t1.join();
    t2.join();
    t3.join();
    t4.join();
}

pub fn run_all_sorts_bench_with_check_simul(comptime use_gpa: bool) !void {
    var t1 = try std.Thread.spawn(.{}, run_mergesort_bench_with_check, .{ use_gpa });
    var t2 = try std.Thread.spawn(.{}, run_quicksort_bench_with_check, .{ use_gpa });
    var t4 = try std.Thread.spawn(.{}, run_heapsort_bench_with_check,  .{ use_gpa });
    var t3 = try std.Thread.spawn(.{}, run_stdsort_bench_with_check,   .{ use_gpa });

    t1.join();
    t2.join();
    t3.join();
    t4.join();
}

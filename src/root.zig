//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const print = std.debug.print;
const rand = std.Random;
const time = std.time;

const thread = std.Thread;

const HEURISTICS = &[_]usize { 5, 13, 20, 7, 15, 10, 6, 10, 5, 13, 4, 0 };

pub fn go() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
  const allocator = gpa.allocator();
  defer _ = gpa.deinit();

  // var prng = rand.DefaultPrng.init(blk: {
  //   var seed: u64 = undefined;
  //   try std.posix.getrandom(std.mem.asBytes(&seed));
  //   break :blk seed;
  // });
  // const random = prng.random();

  // const arr1 = try allocator.alloc(i32, 1_000_000);
  // const arr2 = try allocator.alloc(i32, 1_000_000);
  // const arr3 = try allocator.alloc(i32, 1_000_000);

  // defer {
  //   allocator.free(arr1);
  //   allocator.free(arr2);
  //   allocator.free(arr3);
  // }

  // for(arr1, arr2, arr3) |*x, *y, *z| {
  //   x.* = random.intRangeAtMost(i32, 1, 8_000_000);
  //   y.* = x.*;
  //   z.* = x.*;
  // }

  // const t1 = try thread.spawn(.{}, qs, .{ i32, arr1 });
  // const t2 = try thread.spawn(.{}, s,  .{ i32, arr2 });
  // const t3 = try thread.spawn(.{}, ms, .{ i32, arr3 });

  // thread.join(t1);
  // thread.join(t2);
  // thread.join(t3);

  // print("\nDone!\n", .{});

  var graph = [_][]const usize {
    &[_]usize { 0,  4,  0,  12, 0,  0,  0,  0,  0,  0,  0,  0 },
    &[_]usize { 4,  0,  8,  0,  15, 0,  0,  0,  0,  0,  0,  0 },
    &[_]usize { 0,  8,  0,  0,  0,  10, 0,  0,  0,  0,  0,  0 },
    &[_]usize { 12, 0,  0,  0,  2,  0,  7,  0,  0,  0,  0,  0 },
    &[_]usize { 0,  15, 0,  2,  0,  6,  0,  9,  0,  0,  0,  0 },
    &[_]usize { 0,  0,  10, 0,  6,  0,  0,  0,  9,  0,  0,  0 },
    &[_]usize { 0,  0,  0,  7,  0,  0,  0,  3,  0,  5,  0,  0 },
    &[_]usize { 0,  0,  0,  0,  9,  0,  3,  0,  0,  0,  17, 0 },
    &[_]usize { 0,  0,  0,  0,  0,  9,  0,  0,  0,  0,  0,  14},
    &[_]usize { 0,  0,  0,  0,  0,  0,  5,  0,  0,  0,  8,  0 },
    &[_]usize { 0,  0,  0,  0,  0,  0,  0,  17, 0,  8,  0,  10},
    &[_]usize { 0,  0,  0,  0,  0,  0,  0,  0,  14, 0,  10, 0 },
  };

  const x = try dfs(allocator, &graph, 0, 11);
  formatPath(usize, x.items);
  x.deinit();

  const y = HCS(usize, &graph, 0, 11);
  formatPath(usize, y.items);
  y.deinit();
}



fn formatPath(comptime T: type, arr: []T) void {
  const n = arr.len - 1;
  for(0..n) |i|
    print("{any} -> ", .{ arr[i] + 1 });
    
  print("{any}\n", .{ arr[n] + 1 });
}


fn HCS(comptime T: type, graph: [][]const T, start: usize, end: usize) std.ArrayList(usize) {
  var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
  const allocator = gpa.allocator();
  defer _ = gpa.deinit();

  var open = std.ArrayList(std.ArrayList(usize)).init(allocator);
  
  defer {
    for(open.items) |*thing| {
      thing.deinit();
    }
    open.deinit();
  }

  var tmp = std.ArrayList(usize).init(allocator);
  tmp.append(start) catch @panic("?");
  open.append(tmp) catch @panic("?");

  while(open.items.len != 0) {
    var path: std.ArrayList(usize) = open.pop();
    const len = path.items.len;
    const curr = path.items[len - 1];

    if(curr == end)
      return path;

    var adjs = std.ArrayList(usize).init(allocator);

    for(graph[curr], 0..) |adj, neighbor| {
      if(adj != 0 and notContains(usize, path.items, neighbor)) {
        adjs.append(neighbor) catch @panic("gg");
      }
    }

    std.mem.sort(usize, adjs.items, {}, lessThanFn);

      // for(adjs.items) |adj| {
      //   var new_path = std.ArrayList(usize).initCapacity(allocator, len + 1) catch @panic("xd");
      //   const another_p = &new_path.items.len;
      //   another_p.* = len + 1;
      //   @memcpy(new_path.items[0..len], path.items);
      //   errdefer new_path.deinit();
      //   const p = &new_path.items[len];
      //   p.* = adj;

      //   open.append(new_path) catch @panic("crap");
      // }
      for (adjs.items) |adj| {
        var new_path = std.ArrayList(usize).init(allocator);
        new_path.appendSlice(path.items) catch @panic("OOM");
        new_path.append(adj) catch @panic("OOM");
        open.append(new_path) catch @panic("OOM");
      }
    path.deinit();
    adjs.deinit();
  }

  return std.ArrayList(usize).init(allocator);
}


fn lessThanFn(_: void, a: usize, b: usize) bool {
  return HEURISTICS[a] > HEURISTICS[b];
}



fn notContains(comptime T: type, arr: []T, target: T) bool {
  for(arr) |thing|
    if(thing == target)
      return false;
      
  return true;
}


fn contains(path: []const usize, node: usize) bool {
  for(path) |n| {
    if(n == node) return true;
  }
  return false;
}

fn dfs(allocator: std.mem.Allocator, graph: [][]const usize, start: usize, finish: usize) !std.ArrayList(usize) {
  var stack = std.ArrayList(std.ArrayList(usize)).init(allocator);
  defer {
    for(stack.items) |path| {
      path.deinit();
    }
    stack.deinit();
  }

  var tmp = std.ArrayList(usize).init(allocator);
  try tmp.append(start);
  try stack.append(tmp);

  while(stack.items.len > 0) {
    var current_path: std.ArrayList(usize) = stack.pop();

    const curr = current_path.getLast();

    if(curr == finish)
      return current_path;

    var i: usize = graph.len;

    while(i > 0) {
      i -= 1;
      if(graph[curr][i] != 0) {
        if(!contains(current_path.items, i)) {
          var new_path = try current_path.clone();
          errdefer new_path.deinit();
          try new_path.append(i);
          try stack.append(new_path);
        }
      }
    }

    current_path.deinit();
  }

  return std.ArrayList(usize).init(allocator);
}


fn swap(comptime T: type, a: *T, b: *T) void {
  const t = a.*;
  a.* = b.*;
  b.* = t;
}

inline fn max(a: anytype, b: anytype) @TypeOf(a) {
  return if(a > b) a else b;
}

inline fn min(a: anytype, b: anytype) @TypeOf(a) {
  return if(a < b) a else b;
}

fn insertionSort(comptime T: type, arr: []T, left: usize, right: usize) void {
  var i: usize = left + 1;
  while(i <= right) : (i += 1) {
    const k = arr[i];
    var j = i;
    while(j > left and arr[j - 1] > k) {
      arr[j] = arr[j - 1];
      j -= 1;
    }
    arr[j] = k;
  }
}

fn quickSort(comptime T: type, arr: []T, left: usize, right: usize) void {
  if(right - left < 24) {
    insertionSort(T, arr, left, right);
    return;
  }

  const mid = (left + right) >> 1;
  if(arr[right] < arr[left])
    swap(T, &arr[right], &arr[left]);
  if(arr[mid]   < arr[left])
    swap(T, &arr[left], &arr[mid]);
  if(arr[mid]   < arr[right])
    swap(T, &arr[mid], &arr[right]);

  const pivot = arr[right];
  var i = left;
  var j = right;

  while(true) {
    i += 1;
    j -= 1;
    while(arr[i] < pivot) : (i += 1) { }
    while(arr[j] > pivot) : (j -= 1) { }
    if(i >= j)
      break;
    swap(T, &arr[i], &arr[j]);
  }

  swap(T, &arr[i], &arr[right]);
  quickSort(T, arr, left,  i - 1);
  quickSort(T, arr, i + 1, right);
}


const RUN = 24;

fn mergeSort(comptime T: type, arr: []T) void {
  const n = arr.len;
  var x: usize = 0;
  while(x < n) : (x += RUN) {
    insertionSort(T, arr, x, min(x + RUN, n) - 1);
  }
  var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
  const allocator = gpa.allocator();
  defer _ = gpa.deinit();

  const buffer = allocator.alloc(T, n) catch @panic("gg");
  var inBuffer = false;

  defer allocator.free(buffer);

  var width: usize = RUN;
  while(width < n) : (width <<= 1) {
    const src = if(inBuffer) buffer else arr;
    const dst = if(inBuffer) arr else buffer;

    var i: usize = 0;
    while(i < n) : (i += width * 2) {
      var l = i;
      var curr = l;
      const mid = min(i + width, n);
      var r = mid;
      const right = min(mid + width, n);

      while(l < mid and r < right) {
        if(src[l] < src[r]) {
          dst[curr] = src[l];
          l += 1;
        }
        else {
          dst[curr] = src[r];
          r += 1;
        }
        curr += 1;
      }

      while(l < mid) : ({
        l += 1;
        curr += 1;
      }) {
        dst[curr] = src[l];
      }

      while(r < right) : ({
        r += 1;
        curr += 1;
      }) {
        dst[curr] = src[r];
      }
    }
    inBuffer = !inBuffer;
  }

  if(inBuffer) {
    @memcpy(arr, buffer);
  }
}


fn qs(comptime T: type, arr: []T) void {
  const start = time.microTimestamp();
  quickSort(T, arr, 0, arr.len - 1);
  const end = time.microTimestamp();

  const timer: f64 = @floatFromInt(end - start);
  print("QS: {d} ms\n", .{ timer / 1000.0 });
}

fn ms(comptime T: type, arr: []T) void {
  const start = time.microTimestamp();
  mergeSort(T, arr);
  const end = time.microTimestamp();

  const timer: f64 = @floatFromInt(end - start);
  print("MS: {d} ms\n", .{ timer / 1000.0 });
}

fn s(comptime T: type, arr: []T) void {
  const start = time.microTimestamp();
  std.mem.sort(T, arr, {}, comptime std.sort.asc(T));
  const end = time.microTimestamp();

  const timer: f64 = @floatFromInt(end - start);
  print("S : {d} ms\n", .{ timer / 1000.0 });
}

//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");


pub fn max(a: anytype, b: anytype) @TypeOf(a) {
  return if(a > b) a else b;
}

pub fn min(a: anytype, b: anytype) @TypeOf(a) {
  return if(a < b) a else b;
}

pub fn swap(comptime T: type, a: *T, b: *T) void {
  const t = a.*;
  a.* = b.*;
  b.* = t;
}

/// Insertion Sort on [left -> right] INCLUSIVELY; [0 -> n] will be for i <= n
pub fn insertionSort(comptime T: type, arr: []T, left: usize, right: usize) void {
  var i: usize = 1;
  while(i <= right) : (i += 1) {
    var j = i;
    const k = arr[i];
    while(j > left and arr[j - 1] > k) {
      arr[j] = arr[j - 1];
      j -= 1;
    }
    arr[j] = k;
  }
}


const RUN = 24;

pub fn mergeSort(comptime T: type, arr: []T, allocator: std.mem.Allocator) void {
  const n = arr.len;
  var x: usize = 0;
  while(x < n) : (x += RUN)
    insertionSort(T, arr, x, max(x + RUN - 1, n - 1));

  // use temp buffer for ease of allocation, copy is faster between 2 objects
  // (might) fit into cache a lot better
  const buffer = allocator.alloc(T, n) catch @panic("ggs");
  var inBuffer = false;

  var width = RUN;
  while(width < n) : (width <<= 1) {
    const src = if(inBuffer) buffer else arr;
    const dst = if(inBuffer) arr else buffer;
    var i: usize = 0;
    while(i < n) : (i += width << 1) {
      var l = i;
      var curr = i;
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

      while(l < mid) : (l += 1) {
        dst[curr] = src[l];
        curr += 1;
      }
      while(r < right) : (r += 1) {
        dst[curr] = src[r];
        curr += 1;
      }
    }
    inBuffer = !inBuffer;
  }

  if(inBuffer)
    @memcpy(arr, buffer); // use std memcpy here if possible!! (~20x performance, but worse memory safety and no type checks)
}


fn qsImpl(comptime T: type, arr: []T, left: usize, right: usize) void {
  if(right - left < RUN) {
    insertionSort(T, arr, left, right);
    return;
  }

  const mid = (left + right) >> 1;
  if(arr[right] < arr[left])
    swap(T, &arr[right], &arr[left]);
  if(arr[mid]   < arr[left])
    swap(T, &arr[left],  &arr[mid]);
  if(arr[mid]   < arr[right])
    swap(T, &arr[right], &arr[mid]);
  
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

  swap(T, &arr[i], &arr[j]);
  qsImpl(T, arr, left,  i - 1);
  qsImpl(T, arr, i + 1, right);
}

/// Zig std sort is block sort (too slow for many allocations and operations)\
/// QS will outperform ~ 1.8x - 2.5x in (~90%) every scenario
pub fn quickSort(comptime T: type, arr: []T) void {
  const n = arr.len;
  if(n > 1) {
    qsImpl(T, arr, 0, n - 1);
  }
}


pub fn isSorted(comptime T: type, arr: []T) bool {
  for(1..arr.len) |i|
    if(arr[i - 1] > arr[i])
      return false;
  
  return true;
}


pub fn SingLL(comptime T: type) type {
  return struct {
    elem: T,
    next: ?*@This(),

    const self = @This();

    /// TODO: Get some functionalities (maybe) for Singly Linked Lists ready?
    pub fn init() void {}
  };
}

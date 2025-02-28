const std = @import("std");


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

fn internal(comptime T: type, arr: []T, left: usize, right: usize) void {
    if(right - left < 24) {
        insertionSort(T, arr, left, right);
        return;
    }

    const mid = (left + right) >> 1;
    if(arr[right] < arr[left])
        swap(T, &arr[right], &arr[left]);
    if(arr[mid] < arr[left])
        swap(T, &arr[mid], &arr[left]);
    if(arr[mid] < arr[right])
        swap(T, &arr[mid], &arr[right]);

    const pivot = arr[right];
    var i = left;
    var j = right;

    while(true) {
        i += 1;
        j -= 1;
        while(arr[i] < pivot) : (i += 1) {}
        while(arr[j] > pivot) : (j -= 1) {}
        
        if(i >= j)
            break;
        swap(T, &arr[i], &arr[j]);
    }

    swap(T, &arr[i], &arr[right]);
    internal(T, arr, left,  i - 1);
    internal(T, arr, i + 1, right);
}


pub fn quickSort(comptime T: type, arr: []T) void {
    const n = arr.len;
    if(n > 1)
        internal(T, arr, 0, n - 1);
}


pub fn mergeSort(comptime T: type, arr: []T) void {
    const n = arr.len;
    if(n <= 16) {
        insertionSort(T, arr, 0, n - 1);
        return;
    }

    const run = n - 16;
    var i: usize = 0;
    while(i < run) : (i += 16)
        insertionSort(T, arr, i, i + 15);
    if(i < n)
        insertionSort(T, arr, i, n - 1);
        
    const allocator = std.heap.c_allocator;
    const buffer = allocator.alloc(T, n) catch {
        @panic("Can't allocate temp buffer, consider other in-place sorts!");
    };
    defer allocator.free(buffer);

    var inBuffer = false;
    var width: usize = 16;
    var src = arr.ptr;
    var dst = buffer.ptr;

    while(width < n) : (width *= 2) {
        i = 0;
        while(i < n) : (i += (width * 2)) {
            const mid: usize = min(i + width, n);
            const right: usize = min(mid + width, n);
            var curr = i;
            var l = i;
            var r = mid;

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
            
            while(l < mid) {
                dst[curr] = src[l];
                curr += 1;
                l += 1;
            }
            while(r < right) {
                dst[curr] = src[r];
                curr += 1;
                r += 1;
            }
        }
        swap([*]T, &src, &dst);
        inBuffer = !inBuffer;
    }

    if(inBuffer) {
        @memcpy(arr, buffer);
    }
}

fn heapify(comptime T: type, arr: []T, size: usize, root: usize) void {
    const tmp: T = arr[root];
    var hole = root;
    var child: usize = hole * 2 + 1;

    while(child < size) {
        if(child + 1 < size and arr[child + 1] > arr[child])
            child += 1;
        if(tmp >= arr[child])
            break;
        
        arr[hole] = arr[child];
        hole = child;
        child = child * 2 + 1;
    }

    arr[hole] = tmp;
}

pub fn heapSort(comptime T: type, arr: []T) void {
    const n = arr.len;
    var i = n / 2;
    while(i != 0) : (i -= 1) {
        heapify(T, arr, n, i - 1);
    }

    i = n - 1;
    while(i != 0) : (i -= 1) {
        swap(T, &arr[0], &arr[i]);
        heapify(T, arr, i, 0);
    }
}


pub inline fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a < b) a else b;
}

pub inline fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a > b) a else b;
}

pub inline fn swap(comptime Type: type, a: *Type, b: *Type) void {
    const t = a.*;
    a.* = b.*;
    b.* = t;
}

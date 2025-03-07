const std = @import("std");
const RUN = 24;


pub fn insertionSort(comptime T: type, arr: []T, left: usize, right: usize) void {
    var i: usize = left + 1;
    while(i <= right) : (i += 1) {
        const k = arr[i];
        var j = i;
        while(j > left and arr[j - 1] > k) : (j -= 1)
            arr[j] = arr[j - 1];
            
        arr[j] = k;
    }
}

/// More operational InserSort, must have a comparator function
///
/// If comparison between a vs b returns true: a then b, else b then a\
/// Less than operator (a < b) sorts ascending, greater than sorts descending
pub fn insertion_sort_functional(comptime T: type, arr: []T, left: usize, right: usize, comptime cmp: fn(a: T, b: T) bool) void {
    var i: usize = left + 1;
    while(i <= right) : (i += 1) {
        const k = arr[i];
        var j = i;
        while(j > left and cmp(k, arr[j - 1])) : (j -= 1)
            arr[j] = arr[j - 1];
            
        arr[j] = k;
    }
}




fn internal(comptime T: type, arr: []T, left: usize, right: usize, cmp: fn(T, T) bool) void {
    if(right - left < RUN) {
        insertion_sort_functional(T, arr, left, right, cmp);
        return;
    }

    const mid = (left + right) >> 1;
    if(cmp(arr[right], arr[left]))
        swap(T, &arr[left], &arr[right]);
    if(cmp(arr[mid], arr[left]))
        swap(T, &arr[left], &arr[mid]);
    if(cmp(arr[mid], arr[right]))
        swap(T, &arr[mid], &arr[right]);

    const pivot = arr[right];
    var i = left;
    var j = right;

    while(true) {
        i += 1;
        j -= 1;
        while(cmp(arr[i], pivot)) i += 1;
        while(cmp(pivot, arr[j])) j -= 1;

        if(i >= j)
            break;
        swap(T, &arr[i], &arr[j]);
    }

    swap(T, &arr[i], &arr[right]);
    internal(T, arr, left, i - 1, cmp);
    internal(T, arr, i + 1, right, cmp);
}

/// Hoare partition, O(n ^ 2) worst case, O(n log(n)) otherwise\
/// O(log(n)) space, but consumes stack frames and stack memory!!\
/// Defaults to < operator for ascending order (use operational for need of complicated comparisons)
/// - Very efficient
/// - Cache-friendly
/// - Super fast
pub fn quickSort(comptime T: type, arr: []T) void {
    const n = arr.len;

    if(n > 1) {
        const lt = struct {
            fn lt(a: T, b: T) bool {
                return a < b;
            }
        }.lt;

        internal(T, arr, 0, n - 1, lt);
    }
}

/// Hoare partition with comparator function, O(n ^ 2) worst case, O(n log(n)) otherwise\
/// O(log(n)) space, but consumes stack frames and stack memory!!
///
/// If comparison between a vs b returns true: a then b, false: b then a\
/// Less than operator (a < b) sorts ascending, greater than sorts descending
/// - Very efficient
/// - Cache-friendly
/// - Super fast
pub fn quick_sort_functional(comptime T: type, arr: []T, comptime cmp: fn(T, T) bool) void {
    const n = arr.len;

    if(n > 1)
        internal(T, arr, 0, n - 1, cmp);
}




/// More operational MergeSort, must take in allocator and comparator function
///
/// If comparison between a vs b returns true: a then b, false: b then a\
/// Less than operator (a < b) sorts ascending, greater than sorts descending
pub fn merge_sort_functional(comptime T: type, allocator: std.mem.Allocator, arr: []T, comptime cmp: fn(a: T, b: T) bool) !void {
    const n = arr.len;
    if(n <= (comptime 8 + RUN)) {
        insertion_sort_functional(T, arr, 0, n - 1, cmp);
        return;
    }

    const run = n - RUN;
    var i: usize = 0;
    while(i < run) : (i += RUN)
        insertion_sort_functional(T, arr, i, i + (comptime RUN - 1), cmp);
    if(i < n)
        insertion_sort_functional(T, arr, i, n - 1, cmp);

    const buffer = try allocator.alloc(T, n);
    defer allocator.free(buffer);

    var inBuffer = false;
    var width: usize = RUN;
    var src = arr.ptr;
    var dst = buffer.ptr;

    while(width < n) : (width *= 2) {
        i = 0;
        while(i < n) : (i += (width * 2)) {
            const mid = min(i + width, n);
            const right = min(mid + width, n);
            merge(T, src, dst, i, mid, right, cmp);
        }
        swap([*]T, &src, &dst);
        inBuffer = !inBuffer;
    }

    if(inBuffer)
        @memcpy(arr, buffer);
}

/// TimSort-ish replica, O(n) best case, O(n log(n)) worst + avg case; Sorts ascension\
/// O(n) space, though blazingly fast and stable!
pub fn mergeSort(comptime T: type, arr: []T) void {
    const n = arr.len;
    const lt = struct {
        fn lt(a: T, b: T) bool {
            return a < b;
        }
    }.lt;

    if(n <= RUN + 8) {
        insertionSort(T, arr, 0, n - 1);
        return;
    }

    const run = n - RUN;
    var i: usize = 0;
    while(i < run) : (i += RUN)
        insertionSort(T, arr, i, i + RUN - 1);
    if(i < n)
        insertionSort(T, arr, i, n - 1);

    const allocator = std.heap.c_allocator;
    const buffer = allocator.alloc(T, n) catch {
        @panic("Can't allocate temp buffer, consider in-place sorts!");
    };
    defer allocator.free(buffer);

    var inBuffer = false;
    var width: usize = RUN;
    var src = arr.ptr;
    var dst = buffer.ptr;

    while(width < n) : (width *= 2) {
        i = 0;
        while(i < n) : (i += width * 2) {
            const mid = min(i + width, n);
            const right = min(mid + width, n);
            merge(T, src, dst, i, mid, right, lt);
        }
        swap([*]T, &src, &dst);
        inBuffer = !inBuffer;
    }

    if(inBuffer)
        @memcpy(arr, buffer);
}

fn merge(comptime T: type, arr: [*]T, buffer: [*]T, left: usize, mid: usize, right: usize, cmp: fn(a: T, b: T) bool) void {
    var i = left;
    var curr = left;
    var j = mid;

    while(i < mid and j < right) : (curr += 1) {
        if(cmp(arr[i], arr[j])) {
            buffer[curr] = arr[i];
            i += 1;
        }
        else {
            buffer[curr] = arr[j];
            j += 1;
        }
    }

    @memcpy(buffer + curr, arr[i..mid]);
    @memcpy(buffer + curr, arr[j..right]);
}




fn heapify(comptime T: type, arr: []T, size: usize, root: usize, comptime cmp: fn(a: T, b: T) bool) void {
    const tmp: T = arr[root];
    var hole = root;
    var child: usize = hole * 2 + 1;

    while(child < size) {
        if(child + 1 < size and cmp(arr[child], arr[child + 1]))
            child += 1;
        if(cmp(arr[child], tmp))
            break;

        arr[hole] = arr[child];
        hole = child;
        child = child * 2 + 1;
    }

    arr[hole] = tmp;
}

pub fn heapSort(comptime T: type, arr: []T) void {
    const lt = struct {
        fn lt(a: T, b: T) bool {
            return a < b;
        }
    }.lt;

    const n = arr.len;
    var i = n / 2;
    while(i != 0) : (i -= 1)
        heapify(T, arr, n, i - 1, lt);

    i = n - 1;
    while(i != 0) : (i -= 1) {
        swap(T, &arr[0], &arr[i]);
        heapify(T, arr, i, 0, lt);
    }
}

/// More operational HeapSort, must provide comparator function\
/// In-place, O(n log(n)) every case
pub fn heap_sort_functional(comptime T: type, arr: []T, cmp: fn(T, T) bool) void {
    const n = arr.len;
    var i = n / 2;
    while(i != 0) : (i -= 1)
        heapify(T, arr, n, i - 1);

    i = n - 1;
    while(i != 0) : (i -= 1) {
        swap(T, &arr[0], &arr[i], cmp);
        heapify(T, arr, i, 0, cmp);
    }
}


inline fn swap(comptime T: type, a: *T, b: *T) void {
    const t = a.*;
    a.* = b.*;
    b.* = t;
}

inline fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if(a < b) a else b;
}

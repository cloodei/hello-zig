//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;


/// Internally stores Allocator, the list [ ] of items, and the current length\
/// Has an internal lessThan operator function, can be exchanged if needed
/// Can be used interchangeably as a Vector
pub fn Stack(comptime T: type) type {
    comptime assert(@sizeOf(T) > 0);
    const lessThan = struct {
        pub inline fn lessThan(a: T, b: T) bool {
            return a < b;
        }
    }.lessThan;

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        items: []T,

        const Self = @This();
        pub var lt = lessThan;

        /// Highly recommend GPA allocator!\
        /// Init Stack with an Allocator and starting cap
        pub fn init(allocator: std.mem.Allocator, comptime cap: usize) Self {
            comptime assert(cap != 0);
            
            const mem = allocator.alloc(T, cap) catch {
                @panic("Failed to init the Stack");
            };

            return Self {
                .len = 0,
                .items = mem,
                .allocator = allocator
            };
        }

        /// Init Stack with a starting cap
        pub inline fn initCap(comptime cap: usize) Self {
            return init(std.heap.c_allocator, cap);
        }

        /// Init Stack with Allocator
        pub inline fn initAllocator(allocator: std.mem.Allocator) Self {
            return init(allocator, 8);
        }

        /// Deallocate Stack
        pub fn deinit(this: *Self) void {
            this.allocator.free(this.items);
        }

        /// Adds 1 element to top of Stack, increments length (resizes in place if possible, else copy resize)
        pub fn push(this: *Self, elem: T) void {
            const len = this.len;
            if(this.capacity() == len) {
                const cap: usize = len * 2;
                if(!this.allocator.resize(this.items, cap)) {
                    const newData = this.allocator.alloc(T, cap) catch {
                        @panic("Can't resize Stack!");
                    };
                    @memcpy(newData.ptr, this.items);

                    this.deinit();
                    this.items = newData;
                }
            }

            this.len += 1;
            this.items[len] = elem;
        }

        /// You know!!
        pub inline fn top(this: *Self) T {
            return this.items[0];
        }

        /// Removes top element from Stack, decrement length
        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            return this.items[this.len];
        }

        /// Check if length is 0
        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        /// Returns inner array's maximum element occupancy
        pub inline fn capacity(this: *Self) usize {
            return this.items.len;
        }

        /// Grab the entire Stack as array (does not copy!! both still own 1 array)
        pub inline fn arr(this: *Self) []T {
            return this.items[0..this.len];
        }

        /// Copy current Stack into array
        pub fn copyIntoArr(this: *Self, buffer: []T) !void {
            assert(buffer.len >= this.len);
            @memcpy(buffer.ptr, this.items[0..this.len]);
        }

        /// Get a new array as copy of the entire Stack
        pub fn getNewArr(this: *Self) ![]T {
            const buffer = try this.allocator.alloc(T, this.len);
            try this.copyIntoArr(buffer);

            return buffer;
        }

        /// Get a new allocated copy of current Stack
        pub fn copy(this: *Self) !Self {
            const buffer = init(this.allocator, this.len);
            try this.copyInto(buffer);

            return buffer;
        }

        /// Copy current Stack into other Stack
        pub fn copyInto(this: *Self, other: Self) !void {
            try this.copyIntoArr(other.items);
            other.len = this.len;
        }

        /// Take complete ownership of other Stack's memory, rendering it undefined\
        /// Frees current Stack
        pub fn take(this: *Self, other: Self) !void {
            this.deinit();
            this.items = other.items;
            this.len = other.len;

            other.len = 0;
            other.items.len = 0;
            other.items.ptr = null;
        }

        /// Sorts entire Stack with comparator function in ascending (default < operator)
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn sort(this: *Self) void {
            quick_sort_functional(T, this.items[0..this.len], this.lt);
        }

        /// Return a new allocated copy of the Stack, sorted in ascending order (default < operator)
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn toSortedArr(this: *Self) ![]T {
            const res = try this.getNewArr();
            quick_sort_functional(T, res, this.lt);

            return res;
        }

        /// Sorts entire Stack with comparator function
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than sorts descending
        pub fn sortSpec(this: *Self, cmp: fn(T, T) bool) void {
            quick_sort_functional(T, this.items[0..this.len], cmp);
        }

        pub fn toSortedArrSpec(this: *Self, cmp: fn(T, T) bool) ![]T {
            const res = try this.getNewArr();
            quick_sort_functional(T, this.items, cmp);
            
            return res;
        }
    };
}

fn internal(comptime T: type, arr: []T, left: usize, right: usize, cmp: fn(T, T) bool) void {
    if(right - left < 24) {
        var i: usize = left + 1;
        while(i <= right) : (i += 1) {
            const k = arr[i];
            var j = i;
            while(j > left and cmp(k, arr[j - 1])) : (j -= 1)
                arr[j] = arr[j - 1];
            
            arr[j] = k;
        }
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
pub fn quick_sort_functional(comptime T: type, arr: []T, comptime cmp: fn(T, T) bool) void {
    const n = arr.len;

    if(n > 1)
        internal(T, arr, 0, n - 1, cmp);
}
inline fn swap(comptime T: type, a: *T, b: *T) void {
    const t = a.*;
    a.* = b.*;
    b.* = t;
}

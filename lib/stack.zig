//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;

/// C MEMCPY IS 10X FASTER AND BETTER (less safe), USE WHENEVER POSSIBLE!!
const memcpy = @cImport({
    @cInclude("string.h");
}).memcpy;

const LengthError = error {MismatchLength, EmptyStack, InsufficientLength};
const PosError = error {InvalidPos};

/// Internally stores Allocator, the list [ ] of items, and the current length\
/// Has an internal lessThan operator function, can be exchanged if needed
/// Can be used interchangeably as a Vector
pub fn Stack(comptime T: type) type {
    comptime assert(@sizeOf(T) > 0);
    const lt = comptime struct {
        fn lt(a: T, b: T) bool { return a < b; }
    }.lt;

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        items: []T,
        len: usize,

        /// If T is [ ]const u8 or [ ]u8, string_representation decides if the
        /// formatter will print an ascii character or a u8 number
        /// 
        /// Defaults to true (prints string of u8 ascii characters), set to false to print numbers naturally
        string_representation: bool,


        /// Highly recommend GPA allocator!\
        /// Init Stack with an Allocator and starting cap
        pub fn init(allocator: std.mem.Allocator, Capacity: usize) Self {
            assert(Capacity != 0);
            
            const mem = allocator.alloc(T, Capacity) catch @panic("Failed to init the Stack");

            return Self {
                .len = 0,
                .items = mem,
                .allocator = allocator,
                .string_representation = true,
            };
        }

        /// Init Stack with a starting cap
        pub inline fn initCap(Capacity: usize) Self {
            return init(std.heap.c_allocator, Capacity);
        }

        /// Init Stack with Allocator
        pub inline fn initAllocator(allocator: std.mem.Allocator) Self {
            return init(allocator, 8);
        }

        /// Deallocate Stack
        pub fn deinit(this: *Self) void {
            this.allocator.free(this.items);
        }

        /// Returns inner array's maximum element occupancy
        pub inline fn capacity(this: Self) usize {
            return this.items.len;
        }

        /// Returns the current amount of occupied space of the Stack
        pub inline fn size(this: Self) usize {
            return this.len;
        }

        /// Grab the entire Stack as array (does not copy!! both still own the 1 array)
        pub inline fn arr(this: Self) []T {
            return this.items[0..this.len];
        }

        /// You know!!
        pub inline fn top(this: Self) T {
            assert(this.len != 0);
            return this.items[this.len - 1];
        }

        /// Check if length is 0
        pub inline fn empty(this: Self) bool {
            return this.len == 0;
        }


        /// Unsafe, unguarded push. Use only when overflow is guaranteed impossible
        /// 
        /// Adds 1 element to top of Stack, increments length, O(1) time
        pub inline fn pushAssumeCap(this: *Self, elem: T) void {
            this.items[this.len] = elem;
            this.len += 1;
        }

        /// Adds 1 element to top of Stack, increments length, amortized O(1) time
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn push(this: *Self, elem: T) void {
            const len = this.len;
            if(this.capacity() == len) {
                const newCap: usize = len * 2;
                if(!this.allocator.resize(this.items, newCap)) {
                    const mem = this.allocator.alloc(T, newCap) catch @panic("Can't resize Stack!");
                    _ = memcpy(@alignCast(@ptrCast(mem.ptr)), @alignCast(@ptrCast(this.items.ptr)), this.len);

                    this.deinit();
                    this.items = mem;
                }
            }

            this.pushAssumeCap(elem);
        }

        /// Adds 1 elem exactly at items[pos] (inclusively, pos allowed from [0..n])\
        /// O(n) time guaranteed, besides pos ~= n
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn insert(this: *Self, elem: T, pos: usize) !void {
            const n = this.len;
            if(pos > n)
                return PosError.InvalidPos;

            if(this.capacity() == n) {
                const newCap: usize = n * 2;
                if(!this.allocator.resize(this.items, newCap)) {
                    const mem = try this.allocator.alloc(T, newCap);
                    _ = memcpy(@alignCast(@ptrCast(mem.ptr)), @alignCast(@ptrCast(this.items)), pos);
                    _ = memcpy(@alignCast(@ptrCast(mem.ptr + pos + 1)),@alignCast(@ptrCast(this.items.ptr + pos)),n - pos);
                    mem[pos] = elem;
                    this.deinit();

                    this.items = mem;
                    this.len += 1;
                    return;
                }
            }
            var i: usize = n;
            while(i != pos) : (i -= 1)
                this.items[i] = this.items[i - 1];

            this.items[pos] = elem;
            this.len += 1;
        }

        /// Adds an element at the first position (bottom of Stack), shifts entire Stack upwards. Full O(n) time
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn unshift(this: *Self, elem: T) !void {
            return this.insert(elem, 0);
        }

        /// Pushes another Stack at the end of current Stack
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn append(this: *Self, other: Self) !void {
            try this.appendArr(other.arr());
        }

        /// Pushes buffer at the end of current Stack
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn appendArr(this: *Self, buffer: []T) !void {
            const extend = buffer.len;
            if(extend == 0)
                return;
                
            const n = this.len;
            const cap = this.capacity();
            if(n + extend >= cap) {
                const resized: usize = if(extend >= cap) cap + extend + 2 * @log2(cap + extend) else cap * 2;
                if(!this.allocator.resize(this.items, resized)) {
                    const mem = try this.allocator.alloc(T, resized);
                    _ = memcpy(@alignCast(@ptrCast(mem.ptr)), @alignCast(@ptrCast(this.items.ptr)), n);

                    this.deinit();
                    this.items = mem;
                }
            }

            _ = memcpy(@alignCast(@ptrCast(this.items.ptr + n)), @alignCast(@ptrCast(buffer.ptr)), extend);
            this.len += extend;
        }

        /// Adds another Stack at exactly items[pos] (allowed from [0..n]), shifting every element above pos to accommodate
        pub fn add(this: *Self, other: Self, pos: usize) !void {
            try this.addArr(other.arr(), pos);
        }
        
        /// Adds buffer at exactly items[pos] (allowed from [0..n]), shifting every element above pos to accommodate
        pub fn addArr(this: *Self, buffer: []T, pos: usize) !void {
            const extend = buffer.len;
            if(extend == 0)
                return;

            const n = this.len;
            if(pos > n)
                return PosError.InvalidPos;

            const cap = this.capacity();
            if(extend + n >= cap) {
                const resized: usize = if(extend >= cap) cap + extend + 2 * @log2(cap + extend) else cap * 2;
                if(!this.allocator.resize(this.items, resized)) {
                    const mem = try this.allocator.alloc(T, resized);
                    var tmp = mem.ptr;
                    _ = memcpy(@alignCast(@ptrCast(tmp)), @alignCast(@ptrCast(this.items.ptr)), pos);
                    tmp += pos;
                    _ = memcpy(@alignCast(@ptrCast(tmp)), @alignCast(@ptrCast(buffer.ptr)), extend);
                    _ = memcpy(@alignCast(@ptrCast(tmp + extend)), @alignCast(@ptrCast(this.items.ptr + pos)), n - pos);

                    this.deinit();
                    this.items = mem;
                    this.len += extend;
                    return;
                }
            }

            for(pos..n) |i|
                this.items[extend + i] = this.items[i];

            _ = memcpy(@alignCast(@ptrCast(this.items + pos)), @alignCast(@ptrCast(buffer.ptr)), extend);
            this.len += extend;
        }


        /// Removes top element from Stack and returns it, decrement length, O(1) time
        pub inline fn pop_safe(this: *Self) ?T {
            if(this.len == 0)
                return null;
            return this.pop();
        }

        /// Removes top element from Stack and returns it, decrement length, O(1) time (no safeguards!! can panic and error out)
        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            return this.items[this.len];
        }

        /// Removes first element (bottom of Stack) from Stack and returns it, decrement length. Shifts entire Stack down, O(n) time
        pub fn shift(this: *Self) !T {
            return this.remove(0);
        }

        /// Removes element at pos from Stack and returns it, decrement length, O(n) time
        pub fn remove(this: *Self, pos: usize) !T {
            if(this.len == 0)
                return LengthError.EmptyStack;
                
            const n = this.len - 1;
            if(pos > n)
                return PosError.InvalidPos;

            var i = pos;
            while(i < n) : (i += 1)
                this.items[i] = this.items[i + 1];
            
            this.len = n;
        }

        /// Crop the last length elements from the Stack
        pub fn truncate(this: *Self, length: usize) LengthError!void {
            if(this.len == 0)
                return LengthError.EmptyStack;
            if(length > this.len)
                return LengthError.InsufficientLength;

            this.len -= length;
        }

        /// Crop all elements from items[start .. end] (inclusively, allowed from [0..n])
        pub fn crop(this: *Self, start: usize, end: usize) LengthError!void {
            const n = this.len;
            if(n == 0)
                return LengthError.EmptyStack;
            if(end < start)
                return LengthError.MismatchLength;

            const len: usize = end - start + 1;
            if(len > n)
                return LengthError.InsufficientLength;

            this.len -= len;
            if(end == n)
                return;
            
            for(end..n, 0..) |pos, i|
                this.items[start + i] = this.items[pos];
        }


        /// Copy current Stack into array
        pub fn copyIntoArr(this: Self, buffer: []T) LengthError!void {
            if(buffer.len >= this.len)
                return LengthError.MismatchLength;

            _ = memcpy(@alignCast(@ptrCast(buffer.ptr)), @alignCast(@ptrCast(this.items.ptr)), this.len);
        }

        /// Copy current Stack into other Stack
        pub fn copyInto(this: Self, other: *Self) !void {
            try this.copyIntoArr(other.items);
            other.len = this.len;
        }

        /// Get a new array as copy of the entire Stack
        pub fn arrCopy(this: Self) ![]T {
            const buffer = try this.allocator.alloc(T, this.len);
            try this.copyIntoArr(buffer);

            return buffer;
        }

        /// Get a new allocated copy of current Stack
        pub fn copy(this: Self) !Self {
            var buffer = init(this.allocator, this.len);
            try this.copyInto(&buffer);

            return buffer;
        }

        /// Take complete ownership of other Stack's memory, rendering it undefined\
        /// Frees current Stack
        pub fn take(this: *Self, other: *Self) LengthError!void {
            if(other.len == 0)
                return LengthError.EmptyStack;

            this.deinit();
            this.items = other.items;
            this.len = other.len;

            other.len = 0;
            other.items.len = 0;
            other.items.ptr = null;
        }


        /// Sorts entire Stack in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn sort(this: *Self) void {
            qsort(this.items[0..this.len], lt);
        }

        /// Return a new Stack as an allocated copy of current Stack, sorted in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn toSorted(this: Self) !Self {
            var buffer = try this.copy();
            buffer.sort();

            return buffer;
        }

        /// Return a new allocated copy of the Stack, sorted in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn toSortedArr(this: Self) ![]T {
            const res = try this.arrCopy();
            qsort(res, lt);

            return res;
        }
        

        /// Sorts entire Stack with comparator function\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than sorts descending
        pub fn sortSpec(this: *Self, comptime cmp: fn(T, T) bool) void {
            qsort(this.items[0..this.len], cmp);
        }

        /// Return a new Stack as an allocated copy of current Stack, sorted according to comparator\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn toSortedSpec(this: Self, comptime cmp: fn(T, T) bool) !Self {
            var buffer = try this.copy();
            buffer.sortSpec(cmp);

            return buffer;
        }

        /// Return a new allocated copy of the Stack, sorted according to comparator\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn toSortedArrSpec(this: Self, comptime cmp: fn(T, T) bool) ![]T {
            const res = try this.arrCopy();
            qsort(res, cmp);
            return res;
        }


        fn internal(array: [*]T, left: usize, right: usize, cmp: fn(a: T, b: T) bool) void {
            if(right - left < 24) {
                var i: usize = left + 1;
                while(i <= right) : (i += 1) {
                    const k = array[i];
                    var j = i;
                    while(j > left and cmp(k, array[j - 1])) : (j -= 1)
                        array[j] = array[j - 1];
                    
                    array[j] = k;
                }
                return;
            }

            const mid = (left + right) >> 1;
            if(cmp(array[right], array[left]))
                swap(&array[left], &array[right]);
            if(cmp(array[mid], array[left]))
                swap(&array[left], &array[mid]);
            if(cmp(array[mid], array[right]))
                swap(&array[mid],  &array[right]);

            const pivot = array[right];
            var i = left;
            var j = right;

            while(true) {
                i += 1;
                j -= 1;
                while(cmp(array[i], pivot)) i += 1;
                while(cmp(pivot, array[j])) j -= 1;

                if(i >= j)
                    break;
                swap(&array[i], &array[j]);
            }

            swap(&array[i], &array[right]);
            internal(array, left, i - 1, cmp);
            internal(array, i + 1, right, cmp);
        }
        inline fn swap(a: *T, b: *T) void {
            const t = a.*;
            a.* = b.*;
            b.* = t;
        }
        fn qsort(array: []T, cmp: fn(T, T) bool) void {
            const n = array.len;

            if(n > 1)
                internal(T, array.ptr, 0, n - 1, cmp);
        }


        /// Formats the Stack for I/O writers, prints each element in their respected formats [ elem, elem, ... ]
        pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.writeAll("[ ");

            for(this.items[0..this.len], 0..) |item, i| {
                if(i > 0)
                    try writer.writeAll(", ");

                const info = @typeInfo(T);
                switch(info) {
                    .pointer => |p| {
                        if(p.size == .slice and p.child == u8) {
                            if(this.string_representation) {
                                try writer.print("\"{s}\"", .{ item });
                            }
                            else {
                                try writer.print("{any}", .{ item });
                            }
                        }
                    },
                    .array  => try writer.print("{any}", .{ item }),
                    else    => try writer.print("{}", .{ item })
                }
            }

            try writer.writeAll(" ]");
        }
    };
}

//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;

pub const LengthError = error{ InsufficientLength, InvalidLength };
pub const PosError = error{ InvalidPos };

/// Internally stores Allocator, the list[ ] of items, and the current length\
/// Has an internal lessThan operator function, can be exchanged if needed\
/// Can be used almost interchangeably as a Vector (ArrayList)
pub fn Stack(comptime T: type) type {
    comptime assert(@sizeOf(T) > 0);
    const info = comptime @typeInfo(T);

    const lt = comptime sw: switch(info) {
        .@"struct", .@"enum", .@"union" => {
            if(@hasDecl(T, "cmp")) {
                break :sw struct {
                    fn lt(a: T, b: T) bool { return a.cmp(b); }
                }.lt;
            }
            else {
                break :sw struct {
                    fn lt(a: T, b: T) bool { return a < b; }
                }.lt;
            }
        },
        else => struct {
            fn lt(a: T, b: T) bool { return a < b; }
        }.lt
    };

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        items: []T,
        len: usize,

        /// If T is [ ]const u8 or [ ]u8, string_representation decides if the
        /// formatter will print an ascii character or a u8 number
        /// 
        /// Defaults to true (prints string of u8 ascii characters), set to false to print numbers naturally
        string_representation: bool = true,


        /// Highly recommend DBA allocator!\
        /// Init Stack with `allocator` and a starting `Capacity`
        pub fn init(allocator: std.mem.Allocator, Capacity: usize) Self {
            assert(Capacity != 0);
            
            const mem = allocator.alloc(T, Capacity) catch @panic("Failed to init the Stack");

            return Self {
                .len = 0,
                .items = mem,
                .allocator = allocator,
            };
        }

        /// Init Stack with a starting `Capacity`
        pub inline fn initCap(Capacity: usize) Self {
            return init(std.heap.smp_allocator, Capacity);
        }

        /// Init Stack with `allocator`
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

        /// Swaps two elements at items[`i`] and items[`j`] (will panic/error out for unallowed indicies)
        pub inline fn swap(this: *Self, i: usize, j: usize) void {
            const t = this.items[i];
            this.items[i] = this.items[j];
            this.items[j] = t;
        }

        /// Attempt a resize with a bigger capacity for the Stack
        pub fn resize(this: *Self, cap: usize) !void {
            if(this.capacity() >= cap)
                return;

            if(!this.allocator.resize(this.items, cap)) {
                const mem = try this.allocator.alloc(T, cap);
                if(this.len != 0)
                    @memcpy(mem.ptr, this.arr());

                this.deinit();
                this.items = mem;
            }
        }

        /// Check if length is 0
        pub inline fn empty(this: Self) bool {
            return this.len == 0;
        }


        /// Unsafe, unguarded push. Use only when overflow is guaranteed impossible
        /// 
        /// Adds `elem` to top of Stack, increments length, O(1) time
        pub inline fn pushAssumeCap(this: *Self, elem: T) void {
            this.items[this.len] = elem;
            this.len += 1;
        }

        /// Adds `elem` to top of Stack, increments length, amortized O(1) time
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn push(this: *Self, elem: T) !void {
            const len = this.len;
            if(this.capacity() == len) {
                const newCap: usize = len * 2;
                if(!this.allocator.resize(this.items, newCap)) {
                    const mem = try this.allocator.alloc(T, newCap);
                    @memcpy(mem.ptr, this.arr());

                    this.deinit();
                    this.items = mem;
                }
            }

            this.pushAssumeCap(elem);
        }

        /// Returns a new allocated Stack as copy of current Stack, with the appended `elem` on top
        pub fn toPush(this: Self, elem: T) !Self {
            const n = this.len;
            const mem = try this.allocator.alloc(T, n + 1);
            @memcpy(mem.ptr, this.items[0..n]);
            mem[n] = elem;

            return Self {
                .allocator = this.allocator,
                .items = mem,
                .len = n + 1,
                .string_representation = this.string_representation,
            };
        }

        /// Adds `elem` exactly at items[`pos`] (inclusively, `pos` allowed from [0..n])\
        /// O(n) time guaranteed, besides `pos` ~= n
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn insert(this: *Self, elem: T, pos: usize) !void {
            const n = this.len;
            if(pos > n)
                return;

            if(this.capacity() == n) {
                const newCap: usize = n * 2;
                if(!this.allocator.resize(this.items, newCap)) {
                    const mem = try this.allocator.alloc(T, newCap);
                    @memcpy(mem.ptr, this.items[0..pos]);
                    @memcpy(mem.ptr + pos + 1, this.items[pos..n]);
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

        /// Adds `elem` at the first position (bottom of Stack), shifts entire Stack upwards. Full O(n) time
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn unshift(this: *Self, elem: T) !void {
            try this.insert(elem, 0);
        }

        /// Pushes `other` Stack at the end of current Stack
        /// 
        /// Resizes in-place if possible, else copy resize on overflow
        pub fn append(this: *Self, other: Self) !void {
            try this.appendArr(other.arr());
        }

        /// Pushes `buffer` at the end of current Stack
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
                    @memcpy(mem.ptr, this.arr());

                    this.deinit();
                    this.items = mem;
                }
            }

            @memcpy(this.items.ptr + n, buffer);
            this.len += extend;
        }

        /// Adds `other` Stack at exactly items[`pos`] (allowed from [0..n]), shifting every element above `pos` to accommodate
        pub fn add(this: *Self, other: Self, pos: usize) !void {
            try this.addArr(other.arr(), pos);
        }
        
        /// Adds `buffer` at exactly items[`pos`] (allowed from [0..n]), shifting every element above `pos` to accommodate
        pub fn addArr(this: *Self, buffer: []T, pos: usize) !void {
            const extend = buffer.len;
            if(extend == 0) {
                @branchHint(.cold);
                return;
            }

            const n = this.len;
            if(pos > n)
                return;

            const cap = this.capacity();
            if(extend + n >= cap) {
                const resized: usize = if(extend >= cap) cap + extend + 2 * @log2(cap + extend) else cap * 2;
                if(!this.allocator.resize(this.items, resized)) {
                    const mem = try this.allocator.alloc(T, resized);
                    var tmp = mem.ptr;

                    @memcpy(tmp, this.items[0..pos]);
                    tmp += pos;
                    @memcpy(tmp, buffer);
                    @memcpy(tmp + extend, this.items[pos..n]);

                    this.deinit();
                    this.items = mem;
                    this.len += extend;
                    return;
                }
            }

            for(pos..n) |i|
                this.items[extend + i] = this.items[i];

            @memcpy(this.items + pos, buffer);
            this.len += extend;
        }


        /// Removes top element from Stack and returns it, decrement length, O(1) time (no safeguards!! can panic and error out)
        pub inline fn popAssumeCap(this: *Self) T {
            this.len -= 1;
            return this.items[this.len];
        }

        /// Removes top element from Stack and returns it (null if empty), decrement length, O(1) time
        pub inline fn pop(this: *Self) ?T {
            if(this.len == 0) {
                @branchHint(.unlikely);
                return null;
            }

            return this.popAssumeCap();
        }

        /// Returns a new allocated copy of current Stack, popped of the last element
        pub fn toPop(this: Self) !Self {
            var res = this.copy();
            if(res.len != 0) {
                @branchHint(.likely);
                res.len -= 1;
            }

            return res;
        }

        /// Removes first element (bottom of Stack) from Stack and returns it, decrement length. Shifts entire Stack down, O(n) time
        pub fn shift(this: *Self) ?T {
            return this.remove(0);
        }

        /// Removes element at exactly items[`pos`] from Stack and returns it, decrement length, O(n) time
        pub fn remove(this: *Self, pos: usize) ?T {
            if(this.len == 0)
                return null;
                
            const n = this.len - 1;
            if(pos > n)
                return null;

            const res = this.items[pos];
            var i = pos;
            while(i < n) : (i += 1)
                this.items[i] = this.items[i + 1];
            
            this.len = n;
            return res;
        }

        /// Crop the last `length` elements from the Stack
        pub fn truncate(this: *Self, length: usize) void {
            if(length > this.len or this.len == 0)
                return;

            this.len -= length;
        }

        /// Crop all elements from [`start`..`end`) (allowed from [0 .. n - 1])
        pub fn crop(this: *Self, start: usize, end: usize) void {
            const n = this.len;
            if(end < start or end > n) {
                @branchHint(.unlikely);
                return;
            }

            for(end..n, start..) |pos, i|
                this.items[i] = this.items[pos];

            this.len -= end - start;
        }


        /// Return the index of the first occurrence of `target` or null if not found
        pub fn find(this: Self, target: T) ?usize {
            for(0..this.len) |i|
                if(this.items[i] == target)
                    return i;
            
            return null;
        }

        /// Return the index of the first occurrence of `target` or null if not found, using `check` between Stack elements and target
        pub fn findSpec(this: Self, target: T, comptime check: fn(a: T, b: T) bool) ?usize {
            for(0..this.len) |i|
                if(check(this.items[i], target))
                    return i;
            
            return null;
        }

        /// Return the amount of `target` currently in the Stack
        pub fn count(this: Self, target: T) usize {
            return this.countSpec(target, comptime struct {
                fn eq(a: T, b: T) bool { return a == b; }
            }.eq);
        }

        /// Return the amount of `target` currently in the Stack, using `check` between Stack elements and target
        pub fn countSpec(this: Self, target: T, comptime check: fn(a: T, b: T) bool) usize {
            var res: usize = 0;

            for(this.arr()) |thing| {
                if(check(thing, target))
                    res += 1;
            }

            return res;
        }

        /// Return whether `target` is in the Stack
        pub fn contains(this: Self, target: T) bool {
            if(this.find(target))
                return true;
            
            return false;
        }

        /// Return whether `target` is in the Stack, using `check` between Stack elements and target
        pub fn containsSpec(this: Self, target: T, comptime check: fn(a: T, b: T) bool) bool {
            if(this.findSpec(target, check))
                return true;
            
            return false;
        }


        /// Copy current Stack into `buffer`
        pub fn copyIntoArr(this: Self, buffer: []T) void {
            if(buffer.len < this.len) {
                @branchHint(.unlikely);
                return;
            }

            @memcpy(buffer.ptr, this.arr());
        }

        /// Copy current Stack into `other` Stack
        pub fn copyInto(this: Self, other: *Self) void {
            this.copyIntoArr(other.items);
            other.len = this.len;
        }

        /// Get a new array as copy of the entire Stack
        pub fn arrCopy(this: Self) ![]T {
            const buffer = try this.allocator.alloc(T, this.len);
            this.copyIntoArr(buffer);

            return buffer;
        }

        /// Get a new allocated copy of current Stack
        pub fn copy(this: Self) Self {
            var buffer = init(this.allocator, this.len);
            this.copyInto(&buffer);

            return buffer;
        }

        /// Take complete ownership of `other` Stack's memory, rendering it undefined (completely O(1), does not copy)
        /// 
        /// other Stack's pointer cannot access its now-moved memory (becomes 0-slice). Current Stack is freed
        pub fn take(this: *Self, other: *Self) void {
            if(other.len == 0)
                return;

            this.deinit();
            this.items = other.items;
            this.len = other.len;

            other.len = 0;
            other.items = &[_]T {};
        }

        /// Take complete ownership of current Stack's memory, rendering it undefined (completely O(1), does not copy)
        /// 
        /// Current Stack's pointer cannot access its now-moved memory (becomes 0-slice)
        pub fn move(this: *Self) Self {
            const res = Self {
                .allocator = this.allocator,
                .items = this.items,
                .len = this.len
            };

            this.len = 0;
            this.items = &[_]T {};

            return res;
        }


        /// Sorts entire Stack in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn sort(this: *Self) void {
            qsort(this.arr(), lt);
        }

        /// Return a new Stack as an allocated copy of current Stack, sorted in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn toSorted(this: Self) Self {
            var buffer = this.copy();
            buffer.sort();

            return buffer;
        }

        /// Return a new allocated array copy of current Stack, sorted in ascending order\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        pub fn toSortedArr(this: Self) ![]T {
            const res = try this.arrCopy();
            qsort(res, lt);

            return res;
        }

        /// Sorts entire Stack with `comp` comparator function\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than sorts descending
        pub fn sortSpec(this: *Self, comptime comp: fn(T, T) bool) void {
            qsort(this.arr(), comp);
        }

        /// Return a new Stack as an allocated copy of current Stack, sorted according to comparator\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn toSortedSpec(this: Self, comptime comp: fn(T, T) bool) Self {
            var buffer = this.copy();
            buffer.sortSpec(comp);

            return buffer;
        }

        /// Return a new allocated array copy of current Stack, sorted according to `comp` comparator function\
        /// Internally uses HP QuickSort, O(n^2) worst case, O(n log(n)) otherwise, O(log(n)) space. Extensibly optimal and fast
        /// 
        /// If comparison between a vs b returns true: a then b, false: b then a\
        /// Less than operator (a < b) sorts ascending, greater than operator (a > b) sorts descending
        pub fn toSortedArrSpec(this: Self, comptime comp: fn(T, T) bool) ![]T {
            const buffer = try this.arrCopy();
            qsort(buffer, comp);

            return buffer;
        }

        /// Sorts entire Stack in ascending order\
        /// Internally uses LSD RadixSort, ~O(256n) time, O(n) space. Fastest possible sort for purely integer Stack
        pub fn sortInt(this: *Self) !void {
            try radixSort(this.items, this.allocator);
        }

        /// Return a new Stack as an allocated copy of current Stack, sorted in ascending order\
        /// Internally uses LSD RadixSort, ~O(256n) time, O(n) space. Fastest possible sort for purely integer Stack
        pub fn toSortedInt(this: Self) Self {
            var buffer = this.copy();
            try buffer.sortInt();

            return buffer;
        }

        /// Return a new allocated array copy of current Stack, sorted in ascending order\
        /// Internally uses LSD RadixSort, ~O(256n) time, O(n) space. Fastest possible sort for purely integer Stack
        pub fn toSortedArrInt(this: Self) ![]T {
            const res = try this.arrCopy();
            try radixSort(res, this.allocator);

            return res;
        }
        

        fn internal(array: [*]T, left: usize, right: usize, comp: fn(a: T, b: T) bool) void {
            if(right - left < 24) {
                var i: usize = left + 1;
                while(i <= right) : (i += 1) {
                    const k = array[i];
                    var j = i;
                    while(j > left and comp(k, array[j - 1])) : (j -= 1)
                        array[j] = array[j - 1];
                    
                    array[j] = k;
                }
                return;
            }

            const mid = (left + right) / 2;
            if(comp(array[right], array[left]))
                _swap(&array[left], &array[right]);
            if(comp(array[mid], array[left]))
                _swap(&array[left], &array[mid]);
            if(comp(array[mid], array[right]))
                _swap(&array[mid],  &array[right]);

            const pivot = array[right];
            var i = left + 1;
            var j = right - 1;

            while(true) : ({ i += 1; j -= 1; }) {
                while(comp(array[i], pivot)) i += 1;
                while(comp(pivot, array[j])) j -= 1;

                if(i >= j)
                    break;
                _swap(&array[i], &array[j]);
            }

            _swap(&array[i], &array[right]);
            internal(array, left, i - 1, comp);
            internal(array, i + 1, right, comp);
        }
        inline fn _swap(a: *T, b: *T) void {
            const t = a.*;
            a.* = b.*;
            b.* = t;
        }
        fn qsort(array: []T, comp: fn(T, T) bool) void {
            const n = array.len;

            if(n > 1) {
                @branchHint(.likely);
                internal(array.ptr, 0, n - 1, comp);
            }
        }
                
        fn radixSort(slice: []T, allocator: std.mem.Allocator) !void {
            const n = slice.len;
            if(n < 2)
                return;

            const UT = comptime sw: switch(info) {
                .int => |_| {
                    var some = info;
                    some.int.signedness = .unsigned;
                    break :sw @Type(some);
                },
                else => {
                    return error{ InvalidType };
                }
            };
            const BitWidth = @bitSizeOf(T);
            const num_passes = comptime (BitWidth + 8 - 1) / 8;
            const sign_flip_mask: UT = comptime (@as(UT, 1) << (BitWidth - 1));

            const buffer = try allocator.alloc(T, n);
            defer allocator.free(buffer);

            var current_slice = slice.ptr;
            var other_slice = buffer.ptr;

            var counts: [256]usize = undefined;
            var pass: usize = 0;
            while(pass < num_passes) : (pass += 1) {
                @memset(&counts, 0);
                const _shift: u6 = @intCast(pass * 8);
                var i: usize = 0;
                while(i < n) : (i += 1) {
                    const u_val = @as(UT, @bitCast(current_slice[i])) ^ sign_flip_mask;
                    const bucket_index: usize = @intCast((@as(usize, u_val) >> _shift) & 255);
                    counts[bucket_index] += 1;
                }

                var prefix_sum: usize = 0;
                i = 0;
                while(i < 256) : (i += 1) {
                    const _count = counts[i];
                    counts[i] = prefix_sum;
                    prefix_sum += _count;
                }

                i = 0;
                while(i < n) : (i += 1) {
                    const item = current_slice[i];
                    const u_val = @as(UT, @bitCast(item)) ^ sign_flip_mask;
                    const bucket_index: usize = @intCast((@as(usize, u_val) >> _shift) & 255);
                    other_slice[counts[bucket_index]] = item;
                    counts[bucket_index] += 1;
                }

                const tmp = current_slice;
                current_slice = other_slice;
                other_slice = tmp;
            }

            if(current_slice != slice.ptr)
                @memcpy(slice, current_slice);
        }


        /// Formats the Stack for I/O writers, use default { } formatting and pass the entire Stack object
        /// 
        /// Prints each element in their respected formats [ elem, elem, ... ]
        pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.writeAll("[ ");

            for(0..this.len) |i| {
                if(i > 0)
                    try writer.writeAll(", ");

                switch(info) {
                    .pointer => |p| {
                        if(p.size == .slice) {
                            if(p.child == u8 and this.string_representation) {
                                try writer.print("\"{s}\"", .{ this.items[i] });
                            }
                            else {
                                try writer.print("{any}", .{ this.items[i] });
                            }
                        }
                    },
                    .array => try writer.print("{any}", .{ this.items[i] }),
                    else   => try writer.print("{}", .{ this.items[i] })
                }
            }

            try writer.writeAll(" ]");
        }
    };
}

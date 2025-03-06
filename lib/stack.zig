//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;

pub fn Stack(comptime T: type) type {
    comptime assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        items: []T,

        const Self = @This();

        pub const _init = init(std.heap.c_allocator, 8);

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
            if(this.items.len == len) {
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

        /// Grab the entire Stack as array (does not copy!! both still own the array)
        pub inline fn getArr(this: *Self) []T {
            return this.items[0..this.len];
        }

        /// Get a new array as copy of the entire Stack
        pub fn getNewArr(this: *Self) ![]T {
            const buffer = try this.allocator.alloc(T, this.len);
            try this.copyIntoArr(buffer);

            return buffer;
        }

        /// Copy current Stack into array
        pub fn copyIntoArr(this: *Self, buffer: []T) !void {
            assert(buffer.len >= this.len);
            @memcpy(buffer.ptr, this.items);
        }

        /// Copy current Stack into other Stack
        pub fn copyInto(this: *Self, other: Stack(T)) !void {
            assert(other.capacity() >= this.len);
            try this.copyIntoArr(other.items);
            other.len = this.len;
        }

        /// Get a new allocated copy of current Stack
        pub fn copy(this: *Self) !Stack(T) {
            const res = init(this.allocator, this.len);
            try this.copyInto(res);

            return res;
        }

        /// Take complete ownership of other Stack's memory, rendering it undefined\
        /// Frees current Stack
        pub fn take(this: *Self, other: Stack(T)) !void {
            this.deinit();
            this.items = other.items;
            this.len = other.len;

            other.items = null;
            other.len = 0;
        }
    };
}

//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;


/// Double-ended Queue, stores allocator internally\
/// Ensures contiguity on resize
pub fn Queue(comptime T: type) type {
    comptime assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        front: usize,
        back: usize,
        items: []T,

        const Self = @This();

        pub const _init = init(std.heap.c_allocator, 8);

        /// (Recommend GPA!)\
        /// Init Queue with an Allocator and a starting cap
        pub fn init(allocator: std.mem.Allocator, comptime cap: usize) Self {
            comptime assert(cap != 0);
            
            const mem = allocator.alloc(T, cap) catch {
                @panic("Nah can't init brother");
            };

            return Self {
                .allocator = allocator,
                .len = 0,
                .front = 0,
                .back = 0,
                .items = mem
            };
        }

        /// Init Queue with a starting cap
        pub inline fn initCap(comptime cap: usize) Self {
            return init(std.heap.c_allocator, cap);
        }

        /// Init Queue with an Allocator
        pub inline fn initAllocator(allocator: std.mem.Allocator) Self {
            return init(allocator, 8);
        }

        /// Deallocate Queue
        pub inline fn deinit(this: *Self) void {
            this.allocator.free(this.items);
        }

        /// Adds 1 elem to back of Queue, increments length (copy resize if necessary)
        pub fn push(this: *Self, elem: T) void {
            const cap = this.capacity();
            if(this.len >= cap - 2) {
                const mem = this.allocator.alloc(T, cap * 2) catch {
                    @panic("Can't alloc my g");
                };

                if(this.front < this.back) {
                    @memcpy(mem.ptr, this.items[this.front..this.back]);
                }
                else {
                    @memcpy(mem.ptr, this.items[this.front..cap]);
                    @memcpy(mem.ptr + (cap - this.front), this.items[0..this.back]);
                }

                this.deinit();

                this.items = mem;
                this.front = 0;
                this.back = this.len;
            }
            this.len += 1;
            this.items[this.back] = elem;
            this.back = (this.back + 1) % cap;
        }

        /// Removes first element of Queue, returning that element, decrements length
        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            defer this.front = (this.front + 1) % this.capacity();
            return this.items[this.front];
        }
        
        /// Returns check if Queue length is 0
        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        /// Get the front of Queue
        pub inline fn first(this: *Self) T {
            return this.items[this.front];
        }

        /// Get the back of Queue
        pub inline fn last(this: *Self) T {
            return this.items[this.back - 1];
        }

        /// Returns inner array's maximum element occupancy
        pub inline fn capacity(this: *Self) usize {
            return this.items.len;
        }

        /// Copy the underlying Queue array to a destination buffer
        pub fn copyIntoArr(this: *Self, buffer: []T) !void {
            assert(buffer.len >= this.len);

            if(this.front < this.back) {
                @memcpy(buffer.ptr, this.items[this.front..this.back]);
            }
            else {
                @memcpy(buffer.ptr, this.items[this.front..this.capacity()]);
                @memcpy(buffer.ptr + (this.capacity() - this.front), this.items[0..this.back]);
            }
        }

        /// Get the full Queue as a new allocated array
        pub fn getNewArr(this: *Self) ![]T {
            const mem = try this.allocator.alloc(T, this.len);
            try this.copyIntoArr(mem);
            return mem;
        }

        /// Copies current Queue into the buffer, sets length = current Queue length\
        /// Stretches/resets Queue contiguity directly
        pub fn copyInto(this: *Self, buffer: Queue(T)) !void {
            try this.copyIntoArr(buffer.items);

            buffer.front = 0;
            buffer.len = this.len;
            buffer.back = buffer.len;
        }

        /// Get a new allocated Queue as copy of current Queue\
        /// Both Queues still own the memory, deinit at caution
        pub fn copy(this: *Self) !Queue(T) {
            const ret = init(this.allocator, this.len);
            try this.copyInto(ret);

            return ret;
        }

        /// Take ownership of another Queue, freeing current Queue\
        /// Old Queue is discarded, stolen q will be undefined
        pub fn take(this: *Self, other: Queue(T)) void {
            this.deinit();
            this.back = other.back;
            this.front = other.front;
            this.items = other.items;
            this.len = other.len;

            other.len = 0;
            other.items.len = 0;
            other.items.ptr = null;
        }
    };
}

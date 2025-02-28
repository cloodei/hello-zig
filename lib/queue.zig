//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");

pub fn Queue(comptime T: type) type {
    comptime std.debug.assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        front: usize,
        back: usize,
        arr: []T,

        const Self = @This();

        pub const _init = init(std.heap.c_allocator, 8);

        /// Recommend GPA!\
        /// Init Queue with an Allocator and a starting cap
        pub fn init(allocator: std.mem.Allocator, comptime cap: usize) Self {
            const mem = allocator.alloc(T, cap) catch {
                @panic("Nah can't init brother");
            };

            return Self {
                .allocator = allocator,
                .len = 0,
                .front = 0,
                .back = 0,
                .arr = mem
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
            this.allocator.free(this.arr);
        }

        /// Adds 1 elem to back of Queue, increments length (copy resize if necessary)
        pub fn push(this: *Self, elem: T) void {
            const cap = this.capacity();
            if(this.len >= cap - 1) {
                const mem = this.allocator.alloc(T, cap * 2) catch {
                    @panic("Can't alloc my g");
                };

                if(this.back > this.front or this.back == 0) {
                    @memcpy(mem.ptr, this.arr[this.front..if(this.back != 0) this.back else cap]);
                }
                else {
                    @memcpy(mem.ptr, this.arr[this.front..cap]);
                    @memcpy(mem.ptr + (cap - this.front), this.arr[0..this.back]);
                }

                this.deinit();

                this.arr = mem;
                this.front = 0;
                this.back = this.len;
            }
            this.len += 1;
            this.arr[this.back] = elem;
            this.back = (this.back + 1) % cap;
        }

        /// Removes first element of Queue, returning that element, decrements length
        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            defer this.front = (this.front + 1) % this.capacity();
            return this.arr[this.front];
        }
        
        /// Returns check if Queue length is 0
        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        /// Get the front of Queue
        pub inline fn first(this: *Self) T {
            return this.arr[this.front];
        }

        /// Get the back of Queue
        pub inline fn last(this: *Self) T {
            return this.arr[this.back - 1];
        }

        /// Returns inner array's max capacity
        pub inline fn capacity(this: *Self) usize {
            return this.arr.len;
        }
    };
}

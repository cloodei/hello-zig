//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const panic = std.debug.panic;

pub fn Queue(comptime T: type) type {
    std.debug.assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        capacity: usize,
        front: usize,
        back: usize,
        arr: [*]T,

        const self = @This();

        pub fn init(comptime cap: usize) self {
            const allocator = std.heap.c_allocator;
            const mem = allocator.alloc(T, cap) catch |err| {
                panic("Nah: {s}", .{ err });
            };

            return self {
                .allocator = allocator,
                .len = 0,
                .capacity = cap,
                .front = 0,
                .back = 0,
                .arr = mem.ptr
            };
        }

        pub inline fn deinit(this: *self) void {
            this.allocator.free(this.arr[0..this.capacity]);
        }

        pub fn push(this: *self, elem: T) void {
            if(this.len >= this.capacity - 4) {
                const cap = this.capacity * 2;
                const mem = this.allocator.alloc(T, cap) catch |err| {
                    panic("Can't alloc my g: ", .{ err });
                };

                if(this.back > this.front or this.back == 0) {
                    @memcpy(mem.ptr, this.arr[this.front..if(this.back != 0) this.back else this.capacity]);
                }
                else {
                    @memcpy(mem.ptr, this.arr[this.front..this.capacity]);
                    @memcpy(mem.ptr + (this.capacity - this.front), this.arr[0..this.back]);
                }

                this.deinit();

                this.arr = mem.ptr;
                this.capacity = cap;
                this.front = 0;
                this.back = this.len;
            }
            this.len += 1;
            this.arr[this.back] = elem;
            this.back = (this.back + 1) % this.capacity;
        }

        pub inline fn pop(this: *self) T {
            this.len -= 1;
            defer this.front = (this.front + 1) % this.capacity;
            return this.arr[this.front];
        }
        
        pub inline fn empty(this: *self) bool {
            return this.len == 0;
        }

        pub inline fn first(this: *self) T {
            return this.arr[this.front];
        }

        pub inline fn last(this: *self) T {
            return this.arr[this.back - 1];
        }
    };
}

//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const panic = std.debug.panic;

pub fn Queue(comptime T: type) type {
    std.debug.assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        front: usize,
        back: usize,
        arr: []T,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return initC(allocator, 1);
        }

        pub fn initC(allocator: std.mem.Allocator, comptime cap: usize) Self {
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

        pub inline fn deinit(this: *Self) void {
            this.allocator.free(this.arr);
        }

        pub fn push(this: *Self, elem: T) void {
            const cap = this.capacity();
            if(this.len >= cap - 1) {
                if(!this.allocator.resize(this.arr, cap * 2)) {

                }
                const mem = this.allocator.alloc(T, cap * 2) catch |err| {
                    panic("Can't alloc my g: ", .{ err });
                };

                if(this.back > this.front or this.back == 0) {
                    @memcpy(mem.ptr, this.arr[this.front..if(this.back != 0) this.back else cap]);
                }
                else {
                    @memcpy(mem.ptr, this.arr[this.front..cap]);
                    @memcpy(mem.ptr + (cap - this.front), this.arr[0..this.back]);
                }

                this.deinit();

                this.arr = mem.ptr;
                this.front = 0;
                this.back = this.len;
            }
            this.len += 1;
            this.arr[this.back] = elem;
            this.back = (this.back + 1) % cap;
        }

        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            defer this.front = (this.front + 1) % this.capacity();
            return this.arr[this.front];
        }
        
        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        pub inline fn first(this: *Self) T {
            return this.arr[this.front];
        }

        pub inline fn last(this: *Self) T {
            return this.arr[this.back - 1];
        }

        pub inline fn capacity(this: *Self) usize {
            return this.arr.len;
        }
    };
}

//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const panic = std.debug.panic;

pub fn Stack(comptime T: type) type {
    std.debug.assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        arr: []T,

        const self = @This();

        pub fn init(comptime cap: usize) self {
            var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
            const allocator = gpa.allocator();

            const mem = allocator.alloc(T, cap) catch {
                panic("Halt!\n", .{});
            };

            return self {
                .len = 0,
                .arr = mem,
                .allocator = allocator
            };
        }

        pub inline fn deinit(this: *self) void {
            this.allocator.free(this.arr);
        }

        pub fn reserve(this: *self, size: usize) void {
            const reserved = this.allocator.alloc(T, size) catch {
                panic("Un-reservable\n", .{});
            };

            this.deinit();
            this.arr = reserved;
        }

        pub fn push(this: *self, elem: T) void {
            if(this.len == this.arr.len) {
                const newData = this.allocator.alloc(T, this.arr.len * 2) catch {
                    panic("Can't alloc my g\n", .{});
                };
                @memcpy(newData[0..this.len], this.arr);

                this.deinit();

                this.arr = newData;
            }
            this.arr[this.len] = elem;
            this.len += 1;
        }

        pub inline fn pop(this: *self) T {
            this.len -= 1;
            return this.arr[this.len];
        }

        pub inline fn empty(this: *self) bool {
            return this.len == 0;
        }

        pub inline fn capacity(this: *self) usize {
            return this.arr.len;
        }
    };
}

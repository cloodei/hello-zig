//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const panic = std.debug.panic;

pub fn Stack(comptime T: type) type {
    std.debug.assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,  // Hope Arena allocation works?
        len: usize,
        arr: []T,

        const Self = @This();

        pub fn init(comptime cap: usize) Self {
            var aa = std.heap.ArenaAllocator.init(std.heap.c_allocator);
            const allocator = aa.allocator();

            const mem = allocator.alloc(T, cap) catch {
                panic("Failed to allocate memory\n", .{});
            };

            return Self {
                .len = 0,
                .arena = aa,
                .arr = mem,
                .allocator = allocator,
            };
        }

        pub fn deinit(this: *Self) void {
            // this.allocator.free(this.arr);
            this.arena.deinit();
        }

        pub fn push(this: *Self, elem: T) void {
            if(this.len == this.arr.len) {
                const newData = this.allocator.alloc(T, this.arr.len * 2) catch {
                    panic("Failed to allocate memory for push\n", .{});
                };
                @memcpy(newData[0..this.len], this.arr);

                // this.allocator.free(this.arr); AAllocator should clear all?
                this.arr = newData;
            }
            this.arr[this.len] = elem;
            this.len += 1;
        }

        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            return this.arr[this.len];
        }

        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        pub inline fn capacity(this: *Self) usize {
            return this.arr.len;
        }
    };
}

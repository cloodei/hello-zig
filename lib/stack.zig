//! Provokes unsafe behaviors for overflow!\
//! Oversized numbers or runtime-available capacity is undefined behavior

const std = @import("std");
const assert = std.debug.assert;

pub fn Stack(comptime T: type) type {
    assert(@sizeOf(T) > 0);

    return struct {
        allocator: std.mem.Allocator,
        len: usize,
        items: []T,

        const Self = @This();

        /// Highly recommend GPA allocator!
        pub fn init(allocator: std.mem.Allocator, comptime cap: usize) Self {
            comptime assert(cap != 0);
            
            const mem = allocator.alloc(T, cap) catch {
                @panic("Failed to init the Stack");
            };
            @memset(mem, undefined);

            return Self {
                .len = 0,
                .items = mem,
                .allocator = allocator
            };
        }

        pub inline fn initC(comptime cap: usize) Self {
            return init(std.heap.c_allocator, cap);
        }

        pub fn deinit(this: *Self) void {
            this.allocator.free(this.items);
        }

        pub fn push(this: *Self, elem: T) void {
            const len = this.len;
            if(this.items.len == len) {
                const cap: usize = len * 2;
                if(!this.allocator.resize(this.items, cap)) {
                    const newData = this.allocator.alloc(T, cap) catch {
                        @panic("Can't push on Stack!");
                    };
                    @memcpy(newData[0..len], this.items);

                    this.deinit();
                    this.items = newData;
                }
            }

            this.len += 1;
            this.items[len] = elem;
        }

        pub inline fn pop(this: *Self) T {
            this.len -= 1;
            return this.items[this.len];
        }

        pub inline fn empty(this: *Self) bool {
            return this.len == 0;
        }

        pub inline fn allocatedSlice(this: *Self) []T {
            return this.items[0..this.len];
        }
    };
}

// const std = @import("std");

// pub fn Stack(comptime T: type) type {
//     std.debug.assert(@sizeOf(T) > 0);

//     return struct {
//         allocator: std.mem.Allocator,
//         capacity: usize,
//         items: []T,

//         const Self = @This();

//         /// Highly recommend GPA allocator!
//         pub fn init(allocator: std.mem.Allocator, comptime cap: usize) Self {
//             var mem = allocator.alloc(T, cap) catch {
//                 @panic("Failed to init the Stack");
//             };
//             @memset(mem, undefined);
//             mem.len = 0;

//             return Self {
//                 .capacity = cap,
//                 .items = mem,
//                 .allocator = allocator
//             };
//         }

//         pub fn initC(comptime cap: usize) Self {
//             return init(std.heap.c_allocator, cap);
//         }

//         pub fn deinit(this: *Self) void {
//             this.allocator.free(this.allocatedSlice());
//         }

//         pub fn push(this: *Self, elem: T) void {
//             const len = this.items.len;
//             if(this.capacity == len) {
//                 const newData = this.allocator.alloc(T, len * 2) catch {
//                     @panic("Can't push on Stack!");
//                 };
//                 @memcpy(newData[0..len], this.items);

//                 this.deinit();
//                 this.items.ptr = newData.ptr;
//             }

//             this.items.len += 1;
//             this.items[len] = elem;
//         }

//         pub inline fn pop(this: *Self) T {
//             const res = this.items[this.items.len - 1];
//             this.items.len -= 1;
//             return res;
//         }

//         pub inline fn empty(this: *Self) bool {
//             return this.items.len == 0;
//         }

//         pub inline fn allocatedSlice(this: *Self) []T {
//             this.items.len = this.capacity;
//             return this.items[0..this.capacity];
//         }
//     };
// }

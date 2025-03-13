const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Error = error{ OutOfMemory, InvalidRange };

const Self = @This();

allocator: Allocator,
buffer: []u8,
len: usize,


pub fn init(allocator: Allocator) Error!Self {
    return Self {
        .allocator = allocator,
        .buffer = try allocator.alloc(u8, 16),
        .len = 0,
    };
}

pub fn init_copy_from(str: Self) Error!Self {
    const mem = try str.allocator.alloc(u8, str.len);
    @memcpy(mem.ptr, str.slice());

    return Self {
        .allocator = str.allocator,
        .buffer = mem,
        .len = str.len,
    };
}

pub fn init_with(str: []const u8) Error!Self {
    return Self {
        .allocator = std.heap.smp_allocator,
        .buffer = @constCast(str),
        .len = str.len,
    };
}

pub fn init_copy_str(str: []const u8) Error!Self {
    const allocator = std.heap.smp_allocator;
    const mem = try allocator.alloc(u8, str.len);
    @memcpy(mem.ptr, str);

    return Self {
        .allocator = allocator,
        .buffer = mem,
        .len = str.len,
    };
}

pub fn slice(this: Self) []u8 {
    return this.buffer[0..this.len];
}

pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("\"{s}\"", .{ this.slice() });
}

const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Error = error{ OutOfMemory, InvalidRange, InvalidLength };

const Self = @This();

allocator: Allocator,
buffer: []u8,
len: usize,


pub fn init(allocator: Allocator) Error!Self {
    return Self{
        .allocator = allocator,
        .buffer = try allocator.alloc(u8, 16),
        .len = 0,
    };
}

pub fn init_from(str: Self) Error!Self {
    const mem = try str.allocator.alloc(u8, str.len);
    @memcpy(mem.ptr, str.slice());

    return Self{
        .allocator = str.allocator,
        .buffer = mem,
        .len = str.len,
    };
}

pub fn init_contents(str: []const u8) Error!Self {
    return Self{
        .allocator = std.heap.smp_allocator,
        .buffer = @constCast(str),
        .len = str.len,
    };
}

pub fn init_copy_str(str: []const u8) Error!Self {
    const allocator = std.heap.smp_allocator;
    const mem = try allocator.alloc(u8, str.len);
    @memcpy(mem.ptr, str);

    return Self{
        .allocator = allocator,
        .buffer = mem,
        .len = str.len,
    };
}

pub fn deinit(this: *Self) void {
    this.allocator.free(this.buffer);
}

pub fn capacity(this: Self) usize {
    return this.buffer.len;
}

pub fn slice(this: Self) []u8 {
    return this.buffer[0..this.len];
}


pub fn concat(this: *Self, string: Self) Error!void {
    if(string.len == 0)
        return;

    try this.concat_str(string.slice());
}

pub fn concat_str(this: *Self, str: []const u8) Error!void {
    const n = this.len;
    try this.resize(n + str.len);
    @memcpy(this.buffer.ptr + n, str);
}

pub fn eql(this: Self, str: Self) bool {
    return std.mem.eql(u8, this.slice(), str.slice());
}

pub fn eql_str(this: Self, str: []const u8) bool {
    return std.mem.eql(u8, this.slice(), str);
}

/// Declare a universal comparator function for future use cases
pub fn cmp(this: Self, other: Self) bool {
    return std.mem.lessThan(u8, this.slice(), other.slice());
}

pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("\"{s}\"", .{this.slice()});
}

pub fn resize(this: *Self, cap: usize) Error!void {
    if(cap <= this.capacity())
        return;

    if(!this.allocator.resize(this.buffer, cap)) {
        const mem = try this.allocator.alloc(u8, cap);
        @memcpy(mem.ptr, this.slice());

        this.deinit();
        this.buffer = mem;
    }
}

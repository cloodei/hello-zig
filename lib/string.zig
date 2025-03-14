const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Error = error{ OutOfMemory, InvalidRange, InvalidLength };

const Self = @This();

allocator: Allocator,
buffer: []u8,
len: usize,


pub inline fn init(allocator: Allocator) Error!Self {
    return Self {
        .allocator = allocator,
        .buffer = try allocator.alloc(u8, 16),
        .len = 0,
    };
}

pub fn init_from(str: Self) Error!Self {
    const mem = try str.allocator.alloc(u8, str.len);
    @memcpy(mem.ptr, str.slice());

    return Self {
        .allocator = str.allocator,
        .buffer = mem,
        .len = str.len,
    };
}

pub fn init_contents(str: []const u8) Error!Self {
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

pub fn deinit(this: *Self) void {
    this.allocator.free(this.buffer);
}

pub inline fn capacity(this: Self) usize {
    return this.buffer.len;
}

pub inline fn slice(this: Self) []u8 {
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

pub fn insert(this: *Self, str: Self, pos: usize) Error!void {
    if(str.len == 0)
        return;

    try this.insert_str(str.slice(), pos);
}

pub fn insert_str(this: *Self, str: []const u8, pos: usize) Error!void {
    const n = this.len;
    if(pos > n)
        return Error.InvalidRange;

    const extend = str.len;
    const cap = this.capacity();
    if(n + extend >= cap) {
        const newCap = if(extend > cap) cap + extend + 2 * @log2(extend + cap + n) else cap * 2;
        if(!this.allocator.resize(this.buffer, newCap)) {
            const mem = try this.allocator.alloc(u8, newCap);
            @memcpy(mem.ptr, this.buffer[0..pos]);
            @memcpy(mem.ptr + pos, str);
            @memcpy(mem.ptr + pos + extend, this.buffer[pos..n]);

            this.deinit();
            this.buffer = mem;
            this.len += extend;
            return;
        }
    }
    @memcpy(this.buffer.ptr + pos + extend, this.buffer[pos..n]);
    @memcpy(this.buffer.ptr + pos, str);
    this.len += extend;
}

pub fn pop(this: *Self) ?u8 {
    if(this.len == 0)
        return null;
    
    return this.pop_assume_cap();
}

pub fn pop_assume_cap(this: *Self) u8 {
    this.len -= 1;
    return this.buffer[this.len];
}

pub fn truncate(this: *Self, len: usize) void {
    const n = this.len;
    if(len > n or n == 0)
        return;
    
    this.len -= len;
}

pub fn remove(this: *Self, substr: Self) void {
    this.remove_str(substr.slice());
}

pub fn remove_str(this: *Self, substr: []const u8) void {
    const index = this.find_str(substr) orelse return;
    if(index) {
        
    }
}


pub fn eql(this: Self, str: Self) bool {
    return std.mem.eql(u8, this.slice(), str.slice());
}

pub fn eql_str(this: Self, str: []const u8) bool {
    return std.mem.eql(u8, this.slice(), str);
}


/// Declare a universal comparator function for future use cases
pub fn cmp(this: Self, other: Self) bool {
    const n = this.len;

    if(n != other.len)
        return n < other.len;

    for(this.buffer[0..n], other.buffer[0..n]) |t, o|
        if(t != o)
            return t < o;
            
    return true;
}

pub fn find(this: Self, substr: Self) ?usize {
    return this.find_str(substr.slice());
}

pub fn find_str(this: Self, substr: []const u8) ?usize {
    return std.mem.indexOf(u8, this.slice(), substr);
}

pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("\"{s}\"", .{ this.slice() });
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

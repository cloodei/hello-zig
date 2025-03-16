const std = @import("std");
const Stack = @import("stack").Stack;
const Allocator = std.mem.Allocator;

pub const Error = error{ OutOfMemory, InvalidRange, InvalidLength };

const Self = @This();

allocator: Allocator,
buffer: []u8,
len: usize,

pub inline fn init(allocator: Allocator) Error!Self {
    return Self{
        .allocator = allocator,
        .buffer = try allocator.alloc(u8, 16),
        .len = 0,
    };
}

pub fn init_from(str: Self) Error!Self {
    const n = str.len;
    const mem = try str.allocator.alloc(u8, n);
    @memcpy(mem.ptr, str.buffer[0..n]);

    return Self{
        .allocator = str.allocator,
        .buffer = mem,
        .len = n,
    };
}

/// Does not allocate, instead takes from a string literal (Do not deinit()!!)
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

pub inline fn capacity(this: Self) usize {
    return this.buffer.len;
}

pub inline fn slice(this: Self) []u8 {
    return this.buffer[0..this.len];
}

pub fn concat(this: *Self, string: Self) Error!void {
    if(string.len == 0) {
        @branchHint(.cold);
        return;
    }

    try this.concat_str(string.slice());
}

pub fn concat_str(this: *Self, str: []const u8) Error!void {
    const n = this.len;
    try this.resize(n + str.len);
    @memcpy(this.buffer.ptr + n, str);
}

pub fn insert(this: *Self, str: Self, pos: usize) Error!void {
    const n = str.len;
    if(n == 0) {
        @branchHint(.cold);
        return;
    }

    try this.insert_str(str.buffer[0..n], pos);
}

pub fn insert_str(this: *Self, str: []const u8, pos: usize) Error!void {
    const n = this.len;
    if(pos > n)
        return;

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
    if(this.len == 0) {
        @branchHint(.unlikely);
        return null;
    }

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
    const n = this.len;
    if(n == 0) {
        @branchHint(.cold);
        return;
    }

    const m = substr.len;
    if(this.find_str(substr)) |index| {
        const crop = m + index;
        for(index..crop, n..) |thing, i| {
            this.buffer[i] = this.buffer[thing];
        }
        this.len -= m;
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

pub fn trim(this: *Self) void {
    this.trim_left();
    this.trim_right();
}

pub fn to_trim(this: Self) !Self {
    var res = try init_from(this);
    res.trim();

    return res;
}

pub fn trim_left(this: *Self) void {
    const n = this.len;
    if(n == 0) {
        @branchHint(.unlikely);
        return;
    }

    var trimmed: usize = 0;
    while(this.buffer[trimmed] == ' ' and trimmed < n)
        trimmed += 1;

    for(trimmed..n, 0..) |j, i|
        this.buffer[i] = this.buffer[j];

    this.len -= trimmed;
}

pub fn trim_right(this: *Self) void {
    var n = this.len;
    if(n == 0) {
        @branchHint(.unlikely);
        return;
    }

    while(this.buffer[n - 1] == ' ') {
        n -= 1;
        if(n == 0) {
            @branchHint(.unlikely);
            break;
        }
    }

    this.len = n;
}

/// Returns a new string with all occurrences of `from` replaced with `to`
pub fn replace(this: Self, from: []const u8, to: []const u8) Error!Self {
    var result = try Self.init(this.allocator);
    var start: usize = 0;

    while(start < this.len) {
        const maybe_pos = std.mem.indexOfPos(u8, this.slice(), start, from);
        if(maybe_pos) |pos| {
            // Add everything up to the match
            try result.concat_str(this.buffer[start..pos]);
            // Add the replacement
            try result.concat_str(to);
            // Move past the match
            start = pos + from.len;
        }
        else {
            // Add the rest of the string
            try result.concat_str(this.buffer[start..this.len]);
            break;
        }
    }

    return result;
}

/// Splits the string by a delimiter and returns an array of strings
pub fn split(this: Self, delimiter: []const u8) Error!Stack(Self) {
    var result = Stack(Self).init(this.allocator, 4);
    var start: usize = 0;

    while(start < this.len) {
        const checkPos = std.mem.indexOfPos(u8, this.slice(), start, delimiter);
        if(checkPos) |pos| {
            var part = try Self.init(this.allocator);
            try part.concat_str(this.buffer[start..pos]);
            try result.push(part);
            start = pos + delimiter.len;
        }
        else {
            var part = try Self.init(this.allocator);
            try part.concat_str(this.buffer[start..this.len]);
            try result.push(part);
            break;
        }
    }

    return result;
}

pub fn to_lower(char: u8) u8 {
    return std.ascii.toLower(char);
}

pub fn to_upper(char: u8) u8 {
    return std.ascii.toUpper(char);
}

/// Converts the string to lowercase
pub fn lower(this: *Self) void {
    for(0..this.len) |i|
        this.buffer[i] = to_lower(this.buffer[i]);
}

/// Converts the string to uppercase
pub fn upper(this: *Self) void {
    for(0..this.len) |i|
        this.buffer[i] = to_upper(this.buffer[i]);
}

/// Returns whether the string starts with `prefix`
pub fn starts_with(this: Self, prefix: []const u8) bool {
    if(prefix.len > this.len)
        return false;

    return std.mem.eql(u8, this.buffer[0..prefix.len], prefix);
}

/// Returns whether the string ends with `suffix`
pub fn ends_with(this: Self, suffix: []const u8) bool {
    const n = this.len;
    if(suffix.len > n)
        return false;

    const start = n - suffix.len;
    return std.mem.eql(u8, this.buffer[start..n], suffix);
}

/// Returns a substring from the given range
pub fn substring(this: Self, start: usize, end: usize) Error!Self {
    if(start > end or end > this.len)
        return;

    var result = try Self.init(this.allocator);
    try result.concat_str(this.buffer[start..end]);
    return result;
}

/// Returns the number of occurrences of a substring
pub fn count(this: Self, substr: []const u8) usize {
    var cnt: usize = 0;
    var start: usize = 0;

    while(start < this.len) {
        const checkPos = std.mem.indexOfPos(u8, this.slice(), start, substr);
        if(checkPos) |pos| {
            cnt += 1;
            start = pos + substr.len;
        }
        else {
            break;
        }
    }

    return cnt;
}

/// Expose a formatter for the String type, printing at the format "buffer[0..n]"
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

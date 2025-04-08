const std = @import("std");
const Stack = @import("stack").Stack;
const Allocator = std.mem.Allocator;

pub const Error = error{ OutOfMemory, InvalidRange, InvalidLength, NaN };

const Self = @This();

allocator: Allocator,
buffer: []u8,
len: usize,


/// Initialize an empty String with `allocator`
pub inline fn init(allocator: Allocator) Error!Self {
    return init_prototype(allocator, 16);
}

/// Initialize an empty String with default allocator
pub inline fn init_default() Error!Self {
    return Self.init(std.heap.smp_allocator);
}

/// Initialize an empty String with `allocator` and `cap`
pub inline fn init_prototype(allocator: Allocator, cap: usize) Error!Self {
    return Self {
        .allocator = allocator,
        .buffer = try allocator.alloc(u8, cap),
        .len = 0,
    };
}

/// Initialize an empty String with default allocator and `cap`
pub fn init_cap(cap: usize) Error!Self {
    return Self.init_prototype(std.heap.smp_allocator, cap);
}

/// Initialize a new allocated copied String from `str`
pub fn init_copy(str: Self) Error!Self {
    const n = str.len;
    const mem = try str.allocator.alloc(u8, n);
    @memcpy(mem.ptr, str.buffer[0..n]);

    return Self {
        .allocator = str.allocator,
        .buffer = mem,
        .len = n,
    };
}

/// Initialize a new allocated String as a copy of `str`
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

/// Does not allocate, instead takes from a string literal (Do not deinit()!! unless a new string was pushed, or resize was caused)
pub fn init_contents(str: []const u8) Error!Self {
    return Self {
        .allocator = std.heap.smp_allocator,
        .buffer = @constCast(str),
        .len = str.len,
    };
}

/// Deallocate String
pub fn deinit(this: *Self) void {
    this.allocator.free(this.buffer);
}


/// Return inner buffer's maximum element occupancy
pub inline fn capacity(this: Self) usize {
    return this.buffer.len;
}

/// Return the entire slice of contained elements/characters in the String
pub inline fn slice(this: Self) []u8 {
    return this.buffer[0..this.len];
}

/// Return a boolean check if String length is empty
pub inline fn empty(this: Self) bool {
    return this.len == 0;
}


/// Push `string` to the end of current String
pub fn concat(this: *Self, string: Self) Error!void {
    if(string.len == 0) {
        @branchHint(.cold);
        return;
    }

    try this.concat_str(string.slice());
}

/// Push `str` to the end of current String
pub fn concat_str(this: *Self, str: []const u8) Error!void {
    const n = this.len;
    try this.resize(n + str.len);
    @memcpy(this.buffer.ptr + n, str);
}

/// Return a newly allocated, concatenated string between current String and `str`
pub fn to_concat(this: Self, str: Self) Error!Self {
    var res = try init_copy(this);
    res.concat(str);
    
    return res;
}

/// Return a newly allocated, concatenated string between current String and `str`
pub fn to_concat_str(this: Self, str: []const u8) Error!Self {
    var res = try init_copy(this);
    res.concat_str(str);

    return res;
}

/// Insert `str` at exactly `pos` index in the String
pub fn insert(this: *Self, str: Self, pos: usize) Error!void {
    const n = str.len;
    if(n == 0) {
        @branchHint(.cold);
        return;
    }

    try this.insert_str(str.buffer[0..n], pos);
}

/// Insert `str` string literal at exactly `pos` index in the String
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


/// Return the character at the end of current String, or null if empty
pub fn pop(this: *Self) ?u8 {
    if(this.len == 0) {
        @branchHint(.unlikely);
        return null;
    }

    return this.pop_assume_cap();
}

/// Return the character at the end of current String (can panic and error out!)
pub fn pop_assume_cap(this: *Self) u8 {
    this.len -= 1;
    return this.buffer[this.len];
}

/// Remove the last `len` characters from current String
pub fn truncate(this: *Self, len: usize) void {
    if(len > this.len) {
        @branchHint(.unlikely);
        return;
    }

    this.len -= len;
}

/// Crop all characters from [`start`..`end`) (allowed from [0 .. n - 1])
pub fn crop(this: *Self, start: usize, end: usize) void {
    const n = this.len;
    if(start > end or end > n) {
        @branchHint(.unlikely);
        return;
    }
    
    for(end..n, start..) |pos, i|
        this.items[i] = this.items[pos];

    this.len -= end - start;
}

/// Remove `substr` from current string
pub fn remove(this: *Self, substr: Self) void {
    this.remove_str(substr.slice());
}

/// Remove `substr` from current string
pub fn remove_str(this: *Self, substr: []const u8) void {
    const n = this.len;
    if(n == 0) {
        @branchHint(.cold);
        return;
    }

    const m = substr.len;
    const index = this.find_str(substr) orelse return;
    const chop = m + index;

    for(index..chop, n..) |j, i|
        this.buffer[i] = this.buffer[j];
        
    this.len -= m;
}

/// Return a newly allocated, trimmed of all whitespace characters (" ") String from current String
pub fn to_trim(this: Self) Error!Self {
    var res = try init_copy(this);
    res.trim();

    return res;
}

/// Trim all whitespace characters (" ") at both ends of the String
pub fn trim(this: *Self) void {
    this.trim_right();
    this.trim_left();
}

/// Trim all whitespace (" ") character at the start of the String
pub fn trim_left(this: *Self) void {
    const n = this.len;
    if(n == 0) {
        @branchHint(.unlikely);
        return;
    }

    var trimmed: usize = 0;
    while(this.buffer[trimmed] == ' ' and trimmed < n)
        trimmed += 1;
    if(trimmed == 0)
        return;

    for(trimmed..n, 0..) |j, i|
        this.buffer[i] = this.buffer[j];

    this.len -= trimmed;
}

/// Trim all whitespace (" ") character at the end of the String
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


/// Return a boolean comparison between current String and `str`
pub fn eql(this: Self, str: Self) bool {
    return std.mem.eql(u8, this.slice(), str.slice());
}

/// Return a boolean comparison between current String and `str`
pub fn eql_str(this: Self, str: []const u8) bool {
    return std.mem.eql(u8, this.slice(), str);
}

/// Find the index of the first occurrence of `substr` in the String
pub fn find(this: Self, substr: Self) ?usize {
    return this.find_str(substr.slice());
}

/// Find the index of the first occurrence of `substr` in the String
pub fn find_str(this: Self, substr: []const u8) ?usize {
    return std.mem.indexOf(u8, this.slice(), substr);
}

/// Return a new string with all occurrences of `from` replaced with `to`
pub fn replace(this: Self, from: []const u8, to: []const u8) Error!Self {
    const n = this.len;
    var result = try Self.init(this.allocator);
    var start: usize = 0;

    while(start < n) {
        const checkPos = std.mem.indexOfPos(u8, this.buffer[0..n], start, from);
        if(checkPos) |pos| {
            try result.concat_str(this.buffer[start..pos]);
            try result.concat_str(to);
            start = pos + from.len;
        }
        else {
            try result.concat_str(this.buffer[start..n]);
            break;
        }
    }

    return result;
}

/// Split the string by `delimiter` and return an array of newly allocated strings
pub fn split(this: Self, delimiter: []const u8) Error!Stack(Self) {
    const n = this.len;
    const m = delimiter.len;

    var result = Stack(Self).init(this.allocator, 4 + 2 * @log2(n));
    var start: usize = 0;

    while(start < n) {
        const checkPos = std.mem.indexOfPos(u8, this.buffer[0..n], start, delimiter);
        if(checkPos) |pos| {
            var part = try Self.init(this.allocator);
            try part.concat_str(this.buffer[start..pos]);
            try result.push(part);
            start = pos + m;
        }
        else {
            var part = try Self.init(this.allocator);
            try part.concat_str(this.buffer[start..n]);
            try result.push(part);
            break;
        }
    }

    return result;
}

/// Split `str` by `delimiter` and return an array of newly allocated strings
pub fn split_str(str: []const u8, delimiter: []const u8) Error!Stack([]u8) {
    const n = str.len;
    const m = delimiter.len;

    const allocator = std.heap.smp_allocator;
    var result = Stack([]u8).init(allocator, 4 + 2 * @log2(n));
    var start: usize = 0;

    while(start < n) {
        const checkPos = std.mem.indexOfPos(u8, str[0..n], start, delimiter);
        if(checkPos) |pos| {
            const part = try allocator.alloc(u8, pos - start);
            @memcpy(part.ptr, str[start..pos]);
            try result.push(part);
            start = pos + m;
        }
        else {
            const part = try allocator.alloc(u8, n - start);
            @memcpy(part.ptr, str[start..n]);
            try result.push(part);
            break;
        }
    }

    return result;
}


/// Return the lowercase character for `char`
pub inline fn to_lower(char: u8) u8 {
    return std.ascii.toLower(char);
}

/// Return the uppercase character for `char`
pub inline fn to_upper(char: u8) u8 {
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


/// Return whether current String starts with `prefix`
pub fn starts_with(this: Self, prefix: Self) bool {
    return this.starts_with_str(prefix.slice());
}

/// Return whether current String starts with `prefix`
pub fn starts_with_str(this: Self, prefix: []const u8) bool {
    if(prefix.len > this.len)
        return false;

    return std.mem.eql(u8, this.buffer[0..prefix.len], prefix);
}

/// Return whether current String ends with `suffix`
pub fn ends_with(this: Self, suffix: Self) bool {
    return this.ends_with_str(suffix.slice());
}

/// Return whether current String ends with `suffix`
pub fn ends_with_str(this: Self, suffix: []const u8) bool {
    const n = this.len;
    if(suffix.len > n)
        return false;

    return std.mem.eql(u8, this.buffer[n - suffix.len..n], suffix);
}

/// Return a substring from `start` to `end` (allowed from [0..n), half-inclusively)
pub fn substring(this: Self, start: usize, end: usize) Error!Self {
    if(start > end or end > this.len)
        return;

    var result = try Self.init(this.allocator);
    try result.concat_str(this.buffer[start..end]);
    return result;
}

/// Return the number of occurrences of `substr`
pub fn count(this: Self, substr: Self) usize {
    return this.count_str(substr.slice());
}

/// Return the number of occurrences of `substr`
pub fn count_str(this: Self, substr: []const u8) usize {
    var cnt: usize = 0;
    var start: usize = 0;

    while(start < this.len) {
        const checkPos = std.mem.indexOfPos(u8, this.slice(), start, substr) orelse break;
        cnt += 1;
        start = checkPos + substr.len;
    }

    return cnt;
}


/// Convert string to integer, return null if invalid format
pub fn str_parse_int(str: []const u8) Error!i128 {
    const n = str.len;
    if(n == 0)
        return Error.InvalidLength;

    var start: usize = 0;
    const negative = str[0] == '-';
    if(negative) {
        if(n == 1)
            return Error.NaN;

        start = 1;
    }

    var acc: i128 = 0;
    while(start != n) : (start += 1) {
        const digit = str[start] -% '0';
        if(digit > 9)
            return Error.NaN;
        acc = acc *% 10 +% digit;
    }

    return if(negative) -acc else acc;
}

/// Convert string to integer, return null if invalid format
pub fn parse_int(str: Self) Error!i128 {
    return str_parse_int(str.slice());
}

/// Read and parse an integer value from stdin until endl character, needs a temp buffer to store input
pub fn read_int_endl(comptime retType: type, buffer: []u8) !retType {
    const stdin = std.io.getStdIn().reader();
    const read = try stdin.readUntilDelimiter(buffer, '\n');
    return @as(retType, @intCast(try str_parse_int(read[0..read.len - 1])));
}

/// Read and parse an integer value from stdin until space character, needs a temp buffer to store input
pub fn read_int(comptime retType: type, buffer: []u8) !retType {
    const stdin = std.io.getStdIn().reader();
    return @as(retType, @intCast(try str_parse_int(try stdin.readUntilDelimiter(buffer, ' '))));
}

/// Read and parse integers from stdin until endl character, needs a temp buffer to store input
///
/// Return a new allocated Stack of `retType` with the given `amount_to_read`
pub fn read_line_ints_to_arr_quantified(comptime retType: type, buffer: []u8, amount_to_read: usize) !Stack(retType) {
    var arr = Stack(retType).init(std.heap.smp_allocator, amount_to_read);
    for(0..amount_to_read - 1) |_|
        arr.pushAssumeCap(try read_int(retType, buffer));
        
    arr.pushAssumeCap(try read_int_endl(retType, buffer));
    return arr;
}

/// Read and parse integers from stdin until endl character, needs a temp buffer to store input
/// 
/// Return a new allocated Stack of `retType`
pub fn read_line_ints_to_arr(comptime retType: type, buffer: []u8) !Stack(retType) {
    const allocator = std.heap.smp_allocator;
    const stdin = std.io.getStdIn().reader();
    const read = try stdin.readUntilDelimiter(buffer, '\n');

    const _split = try split_str(read[0..read.len - 1], " ");
    var arr = Stack(retType).init(allocator, _split.len);
    
    for(_split.items) |item| {
        const parsed: retType = @intCast(try str_parse_int(item));
        arr.pushAssumeCap(parsed);
        allocator.free(item);
    }
    _split.deinit();

    return arr;
}


/// Return `true` if `str` has a lower alphabetical order than `other`, else `false`
pub fn cmp_str(str: []const u8, other: []const u8) bool {
    if(str.len != other.len)
        return str.len < other.len;

    for(str, other) |t, o|
        if(t != o)
            return t < o;

    return true;
}

/// Declare a universal comparator function for future use cases
/// 
/// Return `true` if `this` has a lower alphabetical order than `other`, else `false`
pub fn cmp(this: Self, other: Self) bool {
    const n = this.len;

    if(n != other.len)
        return n < other.len;

    for(this.buffer[0..n], other.buffer[0..n]) |t, o|
        if(t != o)
            return t < o;

    return true;
}

/// Expose a formatter for the String type, printing at the format "`buffer[0..n]`"
pub fn format(this: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("\"{s}\"", .{ this.slice() });
}

/// Attempt an in-place resizing for the String, else copy resize
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

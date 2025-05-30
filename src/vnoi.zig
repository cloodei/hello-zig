const std = @import("std");
const Stack = @import("stack").Stack;
const String = @import("string");

pub fn m26a() !void {
    var dba = std.heap.DebugAllocator(.{}).init;
    const allocator = dba.allocator();
    const readbuf = try allocator.alloc(u8, 256);
    defer allocator.free(readbuf);

    const n = try String.read_int(usize, readbuf);
    const k = try String.read_int_endl(isize, readbuf);

    var arr = Stack(isize).init(allocator, n);
    defer arr.deinit();
    for(0..n - 1) |_|
        try arr.push(try String.read_int(isize, readbuf));
    
    try arr.push(try String.read_int_endl(isize, readbuf));
    
    var ans: usize = 10000;
    inline for(1..7) |i| {
        var res: usize = 0;
        var cur = @as(isize, i);
        for(arr.arr()) |item| {
            res += @abs(item - cur);
            cur += k;
        }
        if(res < ans)
            ans = res;
    }
    std.debug.print("{}\n", .{ ans });
}

pub fn cpp_ptit_41() !void {
    var dba = std.heap.DebugAllocator(.{}).init;
    const allocator = dba.allocator();

    const read_buf = try allocator.alloc(u8, 256);
    defer allocator.free(read_buf);

    const n = try String.read_int_endl(usize, read_buf);
    var stack = try String.read_ints_to_arr(usize, read_buf, n);
    defer stack.deinit();
    stack.sortInt();

    var acc: usize = 0;
    var endres: usize = stack.items[0];
    for(stack.items[1..n]) |item| {
        endres += item;
        acc += endres;
    }
    std.debug.print("{} {}\n", .{ acc, endres });
}

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
    var endres: usize = 0;
    var stack = Stack(usize).init(allocator, n + 1);
    defer stack.deinit();
    for(0..n - 1) |i| {
        stack.items[i] = try String.read_int(usize, read_buf);
        endres += stack.items[i];
    }
    stack.items[n - 1] = try String.read_int_endl(usize, read_buf);
    endres += stack.items[n - 1];
    stack.len = n;
    stack.sortInt();
    std.debug.print("Stack: {}\n", .{ stack });

    var acc: usize = stack.items[0] + stack.items[1];
    for(stack.items[2..n]) |item| {
        acc += (acc + item);
    }
    std.debug.print("{} {}\n", .{ acc, endres });
}

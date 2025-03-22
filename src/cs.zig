const std = @import("std");
const net = std.net;
const fs  = std.fs;


fn send(conn: net.Server.Connection, stdout: fs.File.Writer) !void {
    defer conn.stream.close();

    var buffer: [8192]u8 = undefined;

    const bytes = try conn.stream.read(&buffer);
    try stdout.print("[INFO] Received {} bytes from client - {s}\n", .{ bytes, buffer[0..bytes] });

    _ = try conn.stream.write(
        \\HTTP/1.1 200 OK
        \\Content-Type: text/html; charset=UTF-8
        \\Content-Length: 2000
        \\
        \\<!DOCTYPE html>
        \\<html>
        \\    <head>
        \\        <title>Zig TCP</title>
        \\    </head>
        \\    <body>
        \\        <h1>An là bố</h1>
        \\        <p>hello world!</p>
        \\    </body>
        \\</html>
    );
}

const PORT = 8080;

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    var address = net.Address.initIp4(.{ 0, 0, 0, 0 }, PORT);
    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    try stdout.print("[INFO] Server listening on http://127.0.0.1:{} | http://192.168.1.12:{}\n", .{
        PORT, PORT,
    });

    while(true) {
        const conn = try server.accept();
        errdefer conn.stream.close();

        _ = try std.Thread.spawn(.{}, send, .{ conn, stdout });
    }
}

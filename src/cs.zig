const std = @import("std");
const net = std.net;

fn send(conn: net.Server.Connection, stdout: std.fs.File.Writer) !void {
    defer conn.stream.close();

    var buf: [128]u8 = undefined;

    const bytes = try conn.stream.read(&buf);
    try stdout.print("[INFO] Received {} bytes from client - {s}\n", .{ bytes, buf[0..bytes] });

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
        \\        <p>hello world!</p>
        \\    </body>
        \\</html>
    );
}

const port = 8080;

pub fn main() !void {
    var stdout = std.io.getStdOut().writer();

    var address = try net.Address.resolveIp("0.0.0.0", port);
    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    try stdout.print("[INFO] Server listening on http://{}\n", .{ server.listen_address });

    while(true) {
        const conn = try server.accept();
        errdefer conn.stream.close();

        _ = try std.Thread.spawn(.{}, send, .{ conn, stdout });
    }
}

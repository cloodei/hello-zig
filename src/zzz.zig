const std = @import("std");
const zzz = @import("zzz");
const log = std.log.scoped(.@"examples/basic");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

const Route = http.Route;
const Server = http.Server;
const Router = http.Router;
const Context = http.Context;
const Respond = http.Respond;


fn base_handler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = "Hello, world!",
    });
}

pub fn run() !void {
    const host: []const u8 = "0.0.0.0";
    const port: u16 = 8080;

    var dba = std.heap.DebugAllocator(.{ .thread_safe = true }).init;
    const allocator = dba.allocator();
    defer _ = dba.deinit();

    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    var socket = try Socket.init(.{ .tcp = .{ .host = host, .port = port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(4096);

    var router = try Router.init(allocator, &.{
        Route.init("/").get({}, base_handler).layer(),
    }, .{});
    defer router.deinit(allocator);

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
    };

    try t.entry(
        EntryParams { .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(.{
                    .stack_size = 1024 * 1024 * 4,
                    .socket_buffer_bytes = 1024 * 2,
                    .keepalive_count_max = null,
                    .connection_count_max = 1024,
                });
                try server.serve(rt, p.router, .{ .normal = p.socket });
            }
        }.entry,
    );
}

const std = @import("std");
const env = @import("env.zig");
const Stack = @import("stack").Stack;

const pg = @import("pg");
const zul = @import("zul");
const httpz = @import("httpz");
const PORT = 8080;


inline fn formatTime(num: *f64) u8 {
    if(num.* < 1000.0)
        return 'n';

    num.* /= 1000.0;

    if(num.* >= 1000.0) {
        num.* /= 1000.0;
        return 'm';
    }
    
    return 'u';
}

pub const App = struct {
    allocator: std.mem.Allocator,

    /// Every route will have access with the Handler's\
    /// "global state" data, which is the database Pool
    db: *pg.Pool,

    /// Handler's dispatch, log out timers to process and handle the request
    pub fn dispatch(app: *App, action: httpz.Action(*App), req: *httpz.Request, res: *httpz.Response) !void {
        var timer = try std.time.Timer.start();
        try action(app, req, res);
        var elapsed: f64 = @floatFromInt(timer.lap());
        const tm = formatTime(&elapsed);

        std.debug.print("Method: {s}  |  URL: {s}  |  Status: {d}  |  Time: {d} {c}s\n", .{
            switch(req.method) {
                .GET     => "GET",
                .HEAD    => "HEAD",
                .POST    => "POST",
                .PUT     => "PUT",
                .PATCH   => "PATCH",
                .DELETE  => "DELETE",
                .OPTIONS => "OPTIONS",
                .CONNECT => "CONNECT",
                .OTHER   => "OTHER"
            },
            req.url.path,
            res.status,
            elapsed,
            tm,
        });
    }
};

const Data = struct {
    id: i32,
    name: []const u8,
    flags: i64,
    sys: i16
};

const Nicety = struct {
    id: i32,
    datas_id: i64,
    mem: i64,
    stack: i16,
    info: []const u8,
};

fn index(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "but nobody came...";
}

fn fetchDatas(app: *App, _: *httpz.Request, res: *httpz.Response) !void {
    var vec = Stack(Data).initAllocator(app.allocator);
    defer vec.deinit();

    var thing = try app.db.queryOpts("SELECT * FROM items.datas", .{}, .{ .column_names = true });
    var mapper = thing.mapper(Data, .{});

    while(try mapper.next()) |user| {
        vec.push(user);
    }

    std.debug.print("\n{}\n", .{ vec });

    try res.json(vec.arr(), .{});
}


pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    var pool = try pg.Pool.init(allocator, .{
        .connect = .{
            .port = 5432,
            .host = "127.0.0.1",
        },
        .auth = .{
            .username  = env.username,
            .database = env.database,
            .password = env.password,
        },
    });
    defer pool.deinit();

    var app = App {
        .db = pool,
        .allocator = allocator,
    };

    var server = try httpz.Server(*App).init(allocator, .{ .port = PORT }, &app);
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/", index, .{});

    var datas = router.group("/datas", .{});
    datas.get("/", fetchDatas, .{});

    std.debug.print("Server listing on port: http://localhost:{any}\n", .{ PORT });
    try server.listen();
}

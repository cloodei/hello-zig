const std = @import("std");
const env = @import("env.zig");
const rand = @import("rand");
const utils = @import("utils");
const String = @import("string");
const search = @import("search.zig");
const runner = @import("runner.zig");
const Stack = @import("stack").Stack;

const time = std.time;
const SIZE = 268_435_456; // 256 MB


fn check(dst: anytype, src: anytype) bool {
    for(0..src.len) |i|
        if(src[i] != dst[i])
            return false;

    return true;
}

fn formatTime(num: *f64) u8 {
    if(num.* < 1000.0)
        return 'n';

    num.* /= 1000.0;

    if(num.* >= 1000.0) {
        num.* /= 1000.0;
        return 'm';
    }
    
    return 'u';
}

const pg = @import("pg");
const zul = @import("zul");
const httpz = @import("httpz");
const PORT = 8080;

pub const App = struct {
    allocator: std.mem.Allocator,

    /// Every route will have access with the Handler's\
    /// "global state" data, which is the database Pool
    db: *pg.Pool,

    /// Handler's dispatch, log out timings of each request
    /// in microseconds, time to process and handle the request
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

// pub fn main() !void {
    // var dba = std.heap.DebugAllocator(.{}).init;
    // defer _ = dba.deinit();
    // const allocator = dba.allocator();

    // const src = rand.rand_int_arr_min(i32, allocator, SIZE, 1);
    // defer rand.free_rand_arr(allocator, src);

    // const dst1 = try allocator.alloc(i32, SIZE);
    // var start = time.microTimestamp();
    // utils._memcpy(dst1.ptr, src.ptr, SIZE);
    // var end = time.microTimestamp();
    // const memcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const memcpyCheck = check(dst1, src);
    // allocator.free(dst1);

    // const dst2 = try allocator.alloc(i32, SIZE);
    // start = time.microTimestamp();
    // @memcpy(dst2.ptr, src);
    // end = time.microTimestamp();
    // const stdcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const stdcpyCheck = check(dst2, src);
    // allocator.free(dst2);

    // const dst3 = try allocator.alloc(i32, SIZE);
    // start = time.microTimestamp();
    // var i: usize = 0;
    // while(i != dst3.len) : (i += 1)
    //     dst3[i] = src[i];
    // end = time.microTimestamp();
    // const forcpyTime = @as(f64, @floatFromInt(end - start)) / 1000.0;
    // const forcpyCheck = check(dst3, src);
    // allocator.free(dst3);

    // std.debug.print("Memcpy    : {d} ms | {}\nZig memcpy: {d} ms | {}\nFor memcpy: {d} ms | {}\n", .{
    //     memcpyTime, memcpyCheck,
    //     stdcpyTime, stdcpyCheck,
    //     forcpyTime, forcpyCheck,
    // });

    // var path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.DFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);
    // path = try search.BFS(allocator, 0, 11);
    // search.format(path);
    // allocator.free(path);

    // try runner.run_all_sorts_bench_with_check(false);
    // try runner.run_all_sorts_bench_simul(false);
    // try runner.run_all_sorts_bench(false);

    // try runner.run_memcpys_bench(false);
    // try runner.run_memsets_bench(false);

    // try runner.run_all_search(false);
// }

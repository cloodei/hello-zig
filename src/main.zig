const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const fetchDatas = @import("actions/datas/fetch.zig");
const fetchNiceties = @import("actions/niceties/fetch.zig");
const mutateNiceties = @import("actions/niceties/mutate.zig");
const env = @import("ENV.zig");

const print = std.debug.print;
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
    const elapsed = timer.lap() / 1000;

    print("Method: {s} | URL: {s} | Status: {d} | Time: {d} us\n", .{
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
      elapsed
    });
  }
};

fn index(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
  res.status = 201;
  res.body = "but nobody came...";
}


pub fn main() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{
    // IDK, thread problem? Needs check-in later
    .thread_safe = true
  }){};
  const allocator = gpa.allocator();
  defer _ = gpa.deinit();

  // TODO: Rework Postgres setup later?
  var db = try pg.Pool.init(allocator, .{
    .size = 5,
    .connect = .{
      .port = 5432,
      .host = "localhost"
    },
    .auth = .{
      // ??
    }
  });
  defer db.deinit();

  var app = App {
    .db = db,
    .allocator = allocator
  };

  var server = try httpz.Server(*App).init(allocator, .{
    .port = PORT,
  }, &app);

  defer {
    server.deinit();
    server.stop();
  }

  var router = server.router(.{});
  router.get("/", index, .{});
  
  var usersRoute = router.group("/users", .{});
  usersRoute.get("/", fetchDatas.fetchDatas, .{});
  usersRoute.get("/:id", fetchDatas.fetchData, .{});

  var nicetiesRoute = router.group("/niceties", .{});
  nicetiesRoute.get("/", fetchNiceties.fetchNiceties, .{});
  nicetiesRoute.get("/:id", fetchNiceties.fetchNicety, .{});
  nicetiesRoute.post("/", mutateNiceties.createNiceties, .{});

  print("Server listing on port: http://localhost:{any}\n", .{ PORT });
  try server.listen();
}

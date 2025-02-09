const App = @import("../../main.zig").App;
const httpz = @import("httpz");
const Niceties = @import("../../lib/utils.zig").Niceties;

const ArrayList = @import("std").ArrayList;

/// Get all within items.datas
pub fn fetchNiceties(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
  _ = req;
  const data = try app.db.queryOpts(
    "SELECT * FROM items.niceties",
    .{},
    .{ .column_names = true }
  );
  defer data.deinit();

  var mapper = data.mapper(Niceties, .{});
  var niceties = ArrayList(Niceties).init(app.allocator);
  defer niceties.deinit();

  while(try mapper.next()) |nicety| {
    niceties.append(nicety);
  }

  res.status = 200;
  try res.json(niceties.items, .{});
}

/// Get datas where datas.id = params
pub fn fetchNicety(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
  const id = req.param("id") orelse {
    res.status = 400;
    res.body = "gg you tried";
    return;
  };

  const data = try app.db.queryOpts(
    "SELECT * FROM items.niceties WHERE id = $1",
    .{ id },
    .{ .column_names = true }
  );

  const mapper = data.mapper(Niceties, .{});
  const nicety = try mapper.next() orelse {
    res.status = 200;
    res.body = "not good g";
  };

  res.status = 200;
  res.json(nicety, .{});
}

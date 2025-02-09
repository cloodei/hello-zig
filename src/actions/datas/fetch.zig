const App = @import("../../main.zig").App;
const httpz = @import("httpz");

/// Get all within items.datas
pub fn fetchDatas(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
  _ = app;
  _ = req;
  try res.json(2, .{});
}

/// Fetch datas where datas.id = params
pub fn fetchData(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
  _ = app;
  const id = req.param("id") orelse {
    res.status = 400;
    res.body = "gg you tried";
    return;
  };
  _ = id;

  res.json(3, .{});
}

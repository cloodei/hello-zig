const httpz = @import("httpz");
const App = @import("../../main.zig").App;

pub fn createNiceties(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
  _ = app;
  const body = try req.json(.{}) orelse {
    res.status = 400;
    res.body = "invalid my g";
    return;
  };
  _ = body;

  res.status = 201;
  res.body = "nice";
}


/// TODO: SET method
pub fn updateNiceties() !void {

}

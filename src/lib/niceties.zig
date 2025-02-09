//! DEPRECATED

id: u32,
info: []const u8,
flags: i8,
size: u16,
year: u16,

const self = @This();

pub const data = [_]self {
  .{
    .id = 1,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 2,
    .info = "hello and gg",
    .flags = 8,
    .size = 128,
    .year = 2000
  },
  .{
    .id = 3,
    .info = "taken but not far",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 4,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 5,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 6,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 7,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 8,
    .info = "the phone rings...",
    .flags = -1,
    .size = 0,
    .year = 1
  },
  .{
    .id = 9,
    .info = "but nobody came...?",
    .flags = -64,
    .size = 1,
    .year = 16
  },
  .{
    .id = 10,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 11,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 12,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 13,
    .info = "nah gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 14,
    .info = "it's okay...",
    .flags = -128,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 15,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 16,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 17,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 18,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 19,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 20,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 21,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 22,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 23,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 24,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 25,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 26,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 27,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 28,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 29,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 30,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 31,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 32,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 33,
    .info = "goodbye gg",
    .flags = 0,
    .size = 32,
    .year = 1000
  },
  .{
    .id = 34,
    .info = "it's a wrap gg",
    .flags = 5,
    .size = 32,
    .year = 3000
  },
  .{
    .id = 35,
    .info = "ILoveYou!",
    .flags = 127,
    .size = 32768,
    .year = 8192
  },
  .{
    .id = 36,
    .info = "easy and go gg",
    .flags = 8,
    .size = 128,
    .year = 3000
  },
};

pub const CreateNicetyPayload = struct {
  info: []const u8,
  flags: i8 = 0,
  size: u16 = 32,
  year: u16 = 1000,
};

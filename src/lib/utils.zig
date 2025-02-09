pub const Datas = struct {
  id: i32,
  name: []u8,
  flags: i64,
  sys: i16,
};

pub const Niceties = struct { 
  id: i32,
  datas_id: i64,
  mem: i64,
  stack: i16,
  info: []u8,
};

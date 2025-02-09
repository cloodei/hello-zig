//! Testing custom Arena Allocator?
//! Weak and unsafe, barring memory leaks...
//! (hopefully) More performant than page allocator

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const AAllocator = struct {
  current_ptr: [*]u8,
  end_ptr: [*]u8,
  blocks: std.ArrayList(*[]u8),
  block_size: usize,
  
  const Self = @This();
  
  /// Initialze with a backup allocator (preferrably GPA)\
  /// And blocksize, indicating a starting chunk, pre-allocated
  pub fn init(backing_allocator: Allocator, block_size: usize) !Self {
    var blocks = std.ArrayList(*[]u8).init(backing_allocator);
    const b = try backing_allocator.create([]u8);
    b.* = try backing_allocator.alloc(u8, block_size);
    try blocks.append(b);
    
    return Self{
      .current_ptr = b.*.ptr,
      .end_ptr = b.*.ptr + block_size,
      .blocks = blocks,
      .block_size = block_size,
    };
  }
  
  pub fn allocator(self: *Self) Allocator {
    return .{
      .ptr = self,
      .vtable = &.{
        .alloc = alloc,
        .resize = resize,
        .free = free,
      },
    };
  }
  
  fn alloc(self: *Self, _: *anyopaque, len: usize, ptr_align: u8, _: usize) ?[*]u8 {
    const addr = @intFromPtr(self.current_ptr);
    const aligned_addr = std.mem.alignForward(addr, ptr_align);
    const l = len + (aligned_addr - addr);
    
    if(self.current_ptr + l <= self.end_ptr) {
      const result: [*]u8 = @ptrFromInt(aligned_addr);
      self.current_ptr += l;
      return result;
    }
    
    if(len > self.block_size) {
      const block = self.blocks.allocator.create([]u8) catch return null;
      block.* = self.blocks.allocator.alloc(u8, len) catch {
        self.blocks.allocator.destroy(block);
        return null;
      };
      self.blocks.append(block) catch {
        self.blocks.allocator.free(block.*);
        self.blocks.allocator.destroy(block);
        return null;
      };
      return block.*.ptr;
    }

    const block = self.blocks.allocator.create([]u8) catch return null;
    block.* = self.blocks.allocator.alloc(u8, self.block_size) catch {
      self.blocks.allocator.destroy(block);
      return null;
    };
    self.blocks.append(block) catch {
      self.blocks.allocator.free(block.*);
      self.blocks.allocator.destroy(block);
      return null;
    };
    
    self.current_ptr = block.*.ptr + len;
    self.end_ptr = block.*.ptr + self.block_size;
    return block.*.ptr;
  }
  
  /// TODO: Resize for small chunks, accept less payload
  /// Undecided?
  fn resize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {
    return false;
  }
  
  fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    _ = ctx;
    _ = buf;
    _ = buf_align;
    _ = ret_addr;
  }
  
  /// Deallocate at bulk, freeing all previously allocated memory
  pub fn deinit(self: *Self) void {
    for(self.blocks.items) |block| {
      self.blocks.allocator.free(block.*);
      self.blocks.allocator.destroy(block);
    }
    self.blocks.deinit();
  }
};
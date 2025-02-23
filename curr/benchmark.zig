const std = @import("std");

const Timer = std.time.Timer;
const Allocator = std.mem.Allocator;

/// Calculate statistics from the last N samples
pub const SAMPLE_SIZE = 100;

/// Roughly how long to run the benchmark for
pub var RUN_TIME: u64 = 3 * std.time.ns_per_s;

pub const Result = struct {
	total: u64,
	iterations: u64,
	requested_bytes: usize,

	// sorted, use samples()
	_samples: [SAMPLE_SIZE]u64,

    const self = @This();

	pub fn print(this: *self, name: []const u8) void {
		std.debug.print("{s}\n", .{ name });
		std.debug.print("  {d} iterations\t{d:.2}ns per iterations\n", .{ this.iterations, this.mean() });
		std.debug.print("  {d:.2} bytes per iteration\n", .{ this.requested_bytes / this.iterations });
		std.debug.print("  Worst: {d}ns\tMedian: {d:.2} ns\tStddev: {d:.2} ns\n\n", .{
            this.worst(),
            this.median(),
            this.stdDev()
        });
	}

	pub fn samples(this: *self) []const u64 {
		return this._samples[0..@min(this.iterations, SAMPLE_SIZE)];
	}

	pub fn worst(this: *self) u64 {
		const s = this.samples();
		return s[s.len - 1];
	}

	pub fn mean(this: *self) f64 {
		const s = this.samples();

		var total: u64 = 0;
		for(s) |value| {
			total += value;
		}
		return @as(f64, @floatFromInt(total)) / @as(f64, @floatFromInt(s.len));
	}

	pub fn median(this: *self) u64 {
		const s = this.samples();
		return s[s.len / 2];
	}

	pub fn stdDev(this: *self) f64 {
		const m = this.mean();
		const s = this.samples();

		var total: f64 = 0.0;
		for(s) |value| {
			const t = @as(f64, @floatFromInt(value)) - m;
			total += t * t;
		}
		const variance = total / @as(f64, @floatFromInt(s.len - 1));
		return std.math.sqrt(variance);
	}
};

pub fn run(func: TypeOfBenchmark(void)) !Result {
	return runC({}, func);
}

pub fn runC(context: anytype, func: TypeOfBenchmark(@TypeOf(context))) !Result {
	var gpa = std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = true }) {};
	const allocator = gpa.allocator();
    defer _ = gpa.deinit();

	var total: u64 = 0;
	var iterations: usize = 0;
	var timer = try Timer.start();
	var samples = std.mem.zeroes([SAMPLE_SIZE]u64);

	while(true) {
		iterations += 1;
		timer.reset();

		if(@TypeOf(context) == void) {
			try func(allocator, &timer);
		}
        else {
			try func(allocator, context, &timer);
		}

		const elapsed = timer.lap();
		total += elapsed;
		samples[@mod(iterations, SAMPLE_SIZE)] = elapsed;

		if(total > RUN_TIME)
            break;
	}

	std.sort.heap(u64, samples[0..@min(SAMPLE_SIZE, iterations)], {}, resultLessThan);

	return .{ 
		.total = total,
		._samples = samples,
		.iterations = iterations,
		.requested_bytes = gpa.total_requested_bytes,
	};
}

fn TypeOfBenchmark(comptime T: type) type {
	return switch(T) {
		void => *const fn(Allocator, *Timer) anyerror!void,
		else => *const fn(Allocator, T, *Timer) anyerror!void,
	};
}

fn resultLessThan(_: void, lhs: u64, rhs: u64) bool {
	return lhs < rhs;
}

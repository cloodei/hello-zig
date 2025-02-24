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

	// sorted, use samples()
	_samples: [SAMPLE_SIZE]u64,

    const self = @This();

	pub fn print(this: *self, fnName: []const u8) void {
        var _mean = this.mean();
        var _worst = this.worst();
        var _median = this.median();
        var _stddev = this.stdDev();

        const mfmt  = rounder(f64, &_mean);
        const wfmt  = rounder(u64, &_worst);
        const mdfmt = rounder(u64, &_median);
        const stfmt = rounder(f64, &_stddev);

        var total: f64 = @floatFromInt(this.iterations);
        total *= _mean;
        const totalfmt = rounder(f64, &total);

		std.debug.print("{s}:\n", .{
            fnName
        });
		std.debug.print("  {d} iterations\n  {d:.2} {c}s per iterations\n  {d:.2} total {c}s\n", .{
            this.iterations,
            _mean,
            mfmt,
            total,
            totalfmt
        });
		std.debug.print("  Worst: {d} {c}s  |  Median: {d:.2} {c}s  |  Stddev: {d:.2} {c}s\n\n", .{
            _worst,
            wfmt,
            _median,
            mdfmt,
            _stddev,
            stfmt
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

pub fn run(func: fn(allocator: std.mem.Allocator) anyerror!void) !Result {
	var total: u64 = 0;
	var iterations: usize = 0;
	var timer = try Timer.start();
	var samples = std.mem.zeroes([SAMPLE_SIZE]u64);

    const allocator = std.heap.c_allocator;

	while(true) {
		iterations += 1;
		timer.reset();

        try func(allocator);

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
	};
}

fn rounder(comptime T: type, num: *T) u8 {
    if(num.* < 1000)
        return 'n';

    num.* /= 1000;

    if(num.* >= 1000) {
        num.* /= 1000;
        return 'm';
    }
    
    return 'u';
}

fn resultLessThan(_: void, lhs: u64, rhs: u64) bool {
	return lhs < rhs;
}

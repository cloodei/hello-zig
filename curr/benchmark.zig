const std = @import("std");

const Timer = std.time.Timer;
const Allocator = std.mem.Allocator;

/// Calculate statistics from the last N samples
const SAMPLE_SIZE = 20_000;

/// Roughly how long to run the benchmark
pub var RUN_TIME: u64 = 20 * std.time.ns_per_s;

pub const Result = struct {
    total: u64,
    iterations: u64,
    // sorted, use samples()
    _samples: [SAMPLE_SIZE]u64,

    const self = @This();

    pub fn print(this: *self, fnName: []const u8) void {
        var _mean = this.mean();
        var _worst: f64 = @floatFromInt(this.worst());
        var _best: f64 = @floatFromInt(this.best());
        var _median: f64 = @floatFromInt(this.median());
        var _stddev = this.stdDev();

        const mfmt  = rounder(&_mean);
        const wfmt  = rounder(&_worst);
        const bfmt  = rounder(&_best);
        const mdfmt = rounder(&_median);
        const stfmt = rounder(&_stddev);

        std.debug.print("{s}:\n", .{
            fnName
        });
        std.debug.print("  {d} iterations\n  Mean: {d:.2} {c}s\n", .{
            this.iterations,
            _mean,
            mfmt,
        });
        std.debug.print("  Worst: {d:.2} {c}s  |  Best: {d:.2} {c}s  |  Median: {d:.2} {c}s  |  Stddev: {d:.2} {c}s\n\n",.{
            _worst,
            wfmt,
            _best,
            bfmt,
            _median,
            mdfmt,
            _stddev,
            stfmt,
        });
    }

    pub inline fn samples(this: *self) []const u64 {
        return this._samples[0..@min(this.iterations, SAMPLE_SIZE)];
    }

    pub inline fn worst(this: *self) u64 {
        const s = this.samples();
        return s[s.len - 1];
    }

    pub inline fn best(this: *self) u64 {
        const s = this.samples();
        return s[0];
    }

    pub inline fn mean(this: *self) f64 {
        const s = this.samples();

        var total: u64 = 0;
        for(s) |value| {
            total += value;
        }
        return @as(f64, @floatFromInt(total)) / @as(f64, @floatFromInt(s.len));
    }

    pub inline fn median(this: *self) u64 {
        const s = this.samples();
        return s[s.len / 2];
    }

    pub inline fn stdDev(this: *self) f64 {
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


/// Runs benchmarking on a function that returns a result type of ResType\
/// Forwards the result to resFun, which must be able to consume the returned result
/// 
/// After RUN_TIME seconds, returns a Result object which can print the benchmarks with Result.print()
pub fn runWithReturn(
    comptime ResType: type,
    func: fn(Allocator, *Timer) anyerror!ResType,
    resFun: fn(ResType) anyerror!void,
    comptime use_gpa: bool
) !Result {
	var total: u64 = 0;
	var iterations: usize = 0;
	var samples = std.mem.zeroes([SAMPLE_SIZE]u64);

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = if(use_gpa) gpa.allocator() else std.heap.c_allocator;

	while(true) {
    	var timer = try Timer.start();
        const res = try func(allocator, &timer);
		const elapsed = timer.lap();

        defer if(@typeName(ResType)[0] == '[')
            allocator.free(res);

		samples[iterations % SAMPLE_SIZE] = elapsed;
		iterations += 1;
		total += elapsed;

        try resFun(res);

		if(total >= RUN_TIME)
            break;
	}

	std.sort.heap(u64, samples[0..@min(SAMPLE_SIZE, iterations)], {}, resultLessThan);

	return .{ 
		.total = total,
		._samples = samples,
		.iterations = iterations,
	};
}

/// Runs benchmarking on a noreturn function
/// 
/// After RUN_TIME seconds, returns a Result object which can print the benchmarks with Result.print()
pub fn run(func: fn(allocator: Allocator, timer: *Timer) anyerror!void, comptime use_gpa: bool) !Result {
	var total: u64 = 0;
	var iterations: usize = 0;
	var samples = std.mem.zeroes([SAMPLE_SIZE]u64);

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = if(use_gpa) gpa.allocator() else std.heap.c_allocator;

	while(true) {
	    var timer = try Timer.start();
        try func(allocator, &timer);
		const elapsed = timer.lap();

		samples[iterations % SAMPLE_SIZE] = elapsed;
		iterations += 1;
		total += elapsed;

		if(total >= RUN_TIME)
            break;
	}

	std.sort.heap(u64, samples[0..@min(SAMPLE_SIZE, iterations)], {}, resultLessThan);

	return .{ 
		.total = total,
		._samples = samples,
		.iterations = iterations,
	};
}

fn rounder(num: *f64) u8 {
    if(num.* < 1000.0)
        return 'n';

    num.* /= 1000.0;

    if(num.* >= 1000.0) {
        num.* /= 1000.0;
        return 'm';
    }
    
    return 'u';
}

fn resultLessThan(_: void, lhs: u64, rhs: u64) bool {
	return lhs < rhs;
}

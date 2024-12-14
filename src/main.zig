const std = @import("std");
const aoc = @import("aoc.zig");
const zbench = @import("zbench");

const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");
const day09 = @import("day09.zig");
const day10 = @import("day10.zig");

pub fn main() !void {
    const fs = std.fs;
    const allocator = std.heap.page_allocator;
    const input_dir_path = "./input";

    var input_dir = try fs.cwd().openDir(input_dir_path, .{});
    defer input_dir.close();

    for (1..26) |day| {
        const input_filename = try std.fmt.allocPrint(allocator, "day{d:0>2}.txt", .{day});
        defer allocator.free(input_filename);

        try aoc.check_or_create_file(input_dir, input_filename);

        const test_input_filename = try std.fmt.allocPrint(allocator, "day{d:0>2}_test.txt", .{day});
        defer allocator.free(test_input_filename);
        try aoc.check_or_create_file(input_dir, test_input_filename);
    }

    try day01.day01(.Part_01);
    try day01.day01(.Part_02);
    try day02.day02(.Part_01);
    try day02.day02(.Part_02);
    try day03.day03(.Part_01);
    try day03.day03(.Part_02);
    try day04.day04(.Part_01);
    try day04.day04(.Part_02);
    try day05.day05(.Part_01);
    try day05.day05(.Part_02);
    try day06.day06(.Part_01);
    try day06.day06(.Part_02);
    try day07.day07(.Part_01);
    try day07.day07(.Part_02);
    try day09.day09(.Part_01);
    try day09.day09(.Part_02);
    try day10.day10(.Part_01);
    try day10.day10(.Part_02);
}

fn bench_BenchmarkSomething() void {
    for (0..(1 << 20)) |i| {
        std.debug.print("{d}", .{i});
    }
}

test "bench test" {
    var bench = zbench.Benchmark.init(std.testing.allocator, .{});
    defer bench.deinit();
    try bench.add("My Benchmark", bench_BenchmarkSomething, .{});
    try bench.run(std.io.getStdOut().writer());
}

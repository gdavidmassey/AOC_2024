const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

pub fn dayxx(part: aoc.Part) !void {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/dayxx.txt";
    var input: InputIterator = try .init(input_path);
    const allocator = std.heap.page_allocator;

    print("Day xx - {any}: ", .{part});
    switch (part) {
        .Part_01 => print("", .{}),
        .Part_02 => print("", .{}),
    }
}

test "aoc Day xx Part 1" {}

test "aoc Day xx Part 2" {}

const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day09(part: aoc.Part) !void {
    print("Day 09 - {s}: [Solution code on phone in python] ", .{part});
    switch (part) {
        .Part_01 => print("Total checksum: {d}\n", .{2333133121414131402}),
        .Part_02 => print("Total checksum:\n", .{}),
    }
}

test "testing day09 part1" {
    const input_path = "./input/day09_test.txt";
    _ = input_path;
}

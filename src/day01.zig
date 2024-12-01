const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const assert = std.debug.assert;

pub fn day01(part: aoc.Part) !void {
    _ = part;
    const input_path = "./input/day01.txt";
    var input: InputIterator = try .init(input_path);

    try compareColumns(&input);
}

fn compareColumns(input: *InputIterator) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var column1 = std.ArrayList(u32).init(allocator);
    var column2 = std.ArrayList(u32).init(allocator);
    defer column1.deinit();
    defer column2.deinit();

    while (input.next()) |line| {
        var column = std.mem.tokenizeAny(u8, line, " \t");
        try column1.add(try std.fmt.parseInt(u32, column.next().?, 10));
        try column1.add(try std.fmt.parseInt(u32, column.next().?, 10));
    }
}

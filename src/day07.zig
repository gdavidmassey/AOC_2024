const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day07(part: aoc.Part) !void {
    print("Day 07 - {s}: [Solution code on phone in python] ", .{part});
    switch (part) {
        .Part_01 => print("Total calibration result: {d}\n", .{663613490587}),
        .Part_02 => print("Total calibration result: {d}\n", .{110365987435001}),
    }
}

test "testing day07 part1" {
    const input_path = "./input/day07_test.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var input: InputIterator = try .init(input_path);

    while (input.next()) |line| {
        var line_tokens = std.mem.tokenizeAny(u8, line, " :");
        const total: u32 = try std.fmt.parseInt(u32, line_tokens.next().?, 10);
        var operands: std.ArrayList(u32) = .init(allocator);
        defer operands.deinit();
        while (line_tokens.next()) |token| {
            try operands.append(try std.fmt.parseInt(u32, token, 10));
        }

        print("Total: {d}\n", .{total});
        print("Operands: {any}\n", .{operands.items});
    }
}

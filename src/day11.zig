const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day11(part: aoc.Part) !void {
    const input_path = "./input/day11.txt";
    var input: InputIterator = try .init(input_path);

    const input_stones = input.next().?;
    const blinks: u64 = switch (part) {
        .Part_01 => 25,
        .Part_02 => 75,
    };

    var stokens = std.mem.tokenizeAny(u8, input_stones, " \t");

    var counter: u64 = 0;

    while (stokens.next()) |stoken| {
        counter += 1;
        const a_stone: Stone = .init(try std.fmt.parseInt(u64, stoken, 10));
        try a_stone.blinkN(blinks, &counter);
        print("Initial stone blinked out\n", .{});
    }

    print("Total number of stones after {d} blinks: {d}\n", .{ blinks, counter });
}

const Stone = struct {
    number: u64,

    const Self = @This();

    const Stones = union(enum) {
        One: Stone,
        Two: [2]Stone,
    };

    pub fn init(number: u64) Self {
        return .{ .number = number };
    }

    pub fn blink(self: *const Self) !Stones {
        if (self.number == 0) {
            return Stones{ .One = .init(1) };
        }
        var num_str_buffer: [2 ^ 16]u8 = undefined;
        const num_str = try std.fmt.bufPrint(&num_str_buffer, "{d}", .{self.number});
        if (num_str.len & 1 == 0) {
            return Stones{ .Two = [2]Stone{
                .init(try std.fmt.parseInt(u64, num_str[0 .. num_str.len / 2], 10)),
                .init(try std.fmt.parseInt(u64, num_str[num_str.len / 2 ..], 10)),
            } };
        }
        return Stones{ .One = .init(self.number * 2024) };
    }

    pub fn blinkN(self: *const Self, n: u64, counter: *u64) !void {
        if (n <= 0) return;

        const blink_result: Stones = try self.blink();

        switch (blink_result) {
            .One => |stone| try stone.blinkN(n - 1, counter),
            .Two => |stones| {
                counter.* += 1;
                try stones[0].blinkN(n - 1, counter);
                try stones[1].blinkN(n - 1, counter);
            },
        }
    }
};

test "aoc Day 11 Part 1" {
    const input_path = "./input/day11_test.txt";
    var input: InputIterator = try .init(input_path);

    const input_stones = input.next().?;

    var stokens = std.mem.tokenizeAny(u8, input_stones, " \t");

    var counter: u64 = 0;

    while (stokens.next()) |stoken| {
        counter += 1;
        const a_stone: Stone = .init(try std.fmt.parseInt(u64, stoken, 10));
        try a_stone.blinkN(25, &counter);
    }

    print("{d}\n", .{counter});
}

test "blink" {
    const zero_stone: Stone = .init(0);
    const even_stone: Stone = .init(234342);
    const uneven_stone: Stone = .init(1);
    // print("{any}\n", .{try zero_stone.blink()});
    // print("{any}\n", .{try even_stone.blink()});
    // print("{any}\n", .{try uneven_stone.blink()});

    try std.testing.expectEqual(1, (try zero_stone.blink()).One.number);
    try std.testing.expectEqual(234, (try even_stone.blink()).Two[0].number);
    try std.testing.expectEqual(342, (try even_stone.blink()).Two[1].number);
    try std.testing.expectEqual(2024, (try uneven_stone.blink()).One.number);
}

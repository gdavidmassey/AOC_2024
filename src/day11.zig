const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day11(part: aoc.Part) !void {
    const input_path = "./input/day11.txt";
    var input: InputIterator = try .init(input_path);
    const allocator = std.heap.page_allocator;

    const input_stones = input.next().?;
    const blinks: u64 = switch (part) {
        .Part_01 => 25,
        .Part_02 => 75,
    };

    var stone_map_a: std.AutoHashMap(Stone, u64) = .init(allocator);
    var stokens = std.mem.tokenizeAny(u8, input_stones, " \t");

    while (stokens.next()) |stoken| {
        try stone_map_a.put(.init(try std.fmt.parseInt(u64, stoken, 10)), 1);
    }

    for (0..blinks) |_| {
        var stone_map_b: std.AutoHashMap(Stone, u64) = .init(allocator);
        var map_iter = stone_map_a.iterator();
        while (map_iter.next()) |map_entry| {
            const blink_result = try map_entry.key_ptr.*.blink();
            switch (blink_result) {
                .One => |stone| {
                    const result = try stone_map_b.getOrPut(stone);
                    if (result.found_existing) {
                        result.value_ptr.* += map_entry.value_ptr.*;
                    } else {
                        result.value_ptr.* = map_entry.value_ptr.*;
                    }
                },
                .Two => |stones| {
                    for (stones) |stone| {
                        const result = try stone_map_b.getOrPut(stone);
                        if (result.found_existing) {
                            result.value_ptr.* += map_entry.value_ptr.*;
                        } else {
                            result.value_ptr.* = map_entry.value_ptr.*;
                        }
                    }
                },
            }
        }
        stone_map_a.deinit();
        stone_map_a = stone_map_b;
    }

    var stone_count: u64 = 0;
    var map_iter = stone_map_a.valueIterator();
    while (map_iter.next()) |value| stone_count += value.*;
    print("Day 11 - {any}: ", .{part});
    print("Total number of stones after {d} blinks: {d}\n", .{ blinks, stone_count });
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

    pub fn hash(self: Self) u64 {
        var hasher = std.hash.hasherFnv1a(u64);
        hasher.hash(self.number);
        return hasher.finish();
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

test "aoc Day 11 Part 2" {
    const input_path = "./input/day11.txt";
    const allocator = std.heap.page_allocator;

    var stone_map_a: std.AutoHashMap(Stone, u64) = .init(allocator);
    var input: InputIterator = try .init(input_path);

    const input_stones = input.next().?;

    var stokens = std.mem.tokenizeAny(u8, input_stones, " \t");

    while (stokens.next()) |stoken| {
        try stone_map_a.put(.init(try std.fmt.parseInt(u64, stoken, 10)), 1);
    }

    for (0..75) |_| {
        var stone_map_b: std.AutoHashMap(Stone, u64) = .init(allocator);
        var map_iter = stone_map_a.iterator();
        while (map_iter.next()) |map_entry| {
            const blink_result = try map_entry.key_ptr.*.blink();
            switch (blink_result) {
                .One => |stone| {
                    const result = try stone_map_b.getOrPut(stone);
                    if (result.found_existing) {
                        result.value_ptr.* += map_entry.value_ptr.*;
                    } else {
                        result.value_ptr.* = map_entry.value_ptr.*;
                    }
                },
                .Two => |stones| {
                    for (stones) |stone| {
                        const result = try stone_map_b.getOrPut(stone);
                        if (result.found_existing) {
                            result.value_ptr.* += map_entry.value_ptr.*;
                        } else {
                            result.value_ptr.* = map_entry.value_ptr.*;
                        }
                    }
                },
            }
        }
        stone_map_a.deinit();
        stone_map_a = stone_map_b;
    }

    var stone_count: u64 = 0;
    var map_iter = stone_map_a.valueIterator();
    while (map_iter.next()) |value| stone_count += value.*;
    print("{d}\n", .{stone_count});
}

test "blink" {
    const zero_stone: Stone = .init(0);
    const even_stone: Stone = .init(234342);
    const uneven_stone: Stone = .init(1);

    try std.testing.expectEqual(1, (try zero_stone.blink()).One.number);
    try std.testing.expectEqual(234, (try even_stone.blink()).Two[0].number);
    try std.testing.expectEqual(342, (try even_stone.blink()).Two[1].number);
    try std.testing.expectEqual(2024, (try uneven_stone.blink()).One.number);
}

const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const print = std.debug.print;

pub fn day02(part: aoc.Part) !void {
    const input_path = "./input/day02.txt";
    var input: InputIterator = try .init(input_path);

    var safe_count: u32 = 0;
    const error_tolerance: u32 = switch (part) {
        .Part_01 => 0,
        .Part_02 => 1,
    };
    while (input.next()) |line| {
        switch (Report.init(line, error_tolerance).safety) {
            .Safe => safe_count += 1,
            .Unsafe => {},
        }
    }
    print("Day 02 - {s}: ", .{part});
    print("Total number of safe records with error tolerance {d}: {d}\n", .{ error_tolerance, safe_count });
}

const Direction = enum {
    Increasing,
    Decreasing,
    Unsafe,
};

const Safety = enum {
    Safe,
    Unsafe,
};

const Report = struct {
    data: []const u8,
    safety: Safety = .Unsafe,
    direction: Direction = undefined,
    errorTolerance: u32,

    const Self = @This();

    pub fn init(data: []const u8, errorTolerance: u32) Self {
        var self = Self{ .data = data, .errorTolerance = errorTolerance };
        self.checkSafety() catch unreachable;
        return self;
    }

    fn checkSafety(self: *Self) !void {
        if (try self.checkDirectionSafety(.Increasing)) {
            self.direction = .Increasing;
            self.safety = .Safe;
            return;
        }

        if (try self.checkDirectionSafety(.Decreasing)) {
            self.direction = .Decreasing;
            self.safety = .Safe;
        }
    }

    fn checkDirectionSafety(self: *Self, direction: Direction) !bool {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var errorAllowed = self.errorTolerance;

        const first_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        var prev_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);

        var drop_one_or_two: bool = false;

        if (compare(prev_record, first_record) != direction) {
            if (errorAllowed == 0) {
                return false;
            }
            errorAllowed -= 1;
            drop_one_or_two = true;
        }

        var i: u32 = 0;
        while (token_data.next()) |record| : (i += 1) {
            const current_record = try std.fmt.parseInt(u32, record, 10);
            if (i > 0) drop_one_or_two = false;
            const unsafe_comparison: bool = switch (drop_one_or_two) {
                true => compare(current_record, prev_record) != direction and compare(current_record, first_record) != direction,
                false => compare(current_record, prev_record) != direction,
            };
            if (unsafe_comparison) {
                if (errorAllowed == 0) {
                    return false;
                }
                errorAllowed -= 1;
                continue;
            }
            prev_record = current_record;
        }
        return true;
    }
};

fn compare(a: u32, b: u32) Direction {
    if (a > b and a <= b + 3) {
        return .Increasing;
    } else if (a < b and b <= a + 3) {
        return .Decreasing;
    }
    return .Unsafe;
}

test "aoc day01 part 1" {
    const input_path = "./input/day02_test.txt";
    var input: InputIterator = try .init(input_path);

    var safe_count: u32 = 0;
    while (input.next()) |line| {
        switch (Report.init(line, 0).safety) {
            .Safe => safe_count += 1,
            .Unsafe => {},
        }
    }

    try std.testing.expectEqual(2, safe_count);
}

test "aoc day01 part 2" {
    const input_path = "./input/day02_test.txt";
    var input: InputIterator = try .init(input_path);

    var safe_count: u32 = 0;
    while (input.next()) |line| {
        switch (Report.init(line, 1).safety) {
            .Safe => safe_count += 1,
            .Unsafe => {},
        }
    }
    try std.testing.expectEqual(4, safe_count);
}

test "Test compare()" {
    try std.testing.expectEqual(.Increasing, compare(4, 1));
    try std.testing.expectEqual(.Decreasing, compare(1, 4));
    try std.testing.expectEqual(.Unsafe, compare(5, 1));
    try std.testing.expectEqual(.Unsafe, compare(1, 5));
    try std.testing.expectEqual(.Unsafe, compare(3, 3));
}

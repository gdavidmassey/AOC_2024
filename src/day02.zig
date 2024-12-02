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
    safety: Safety = undefined,
    direction: Direction = undefined,
    errorTolerance: u32,

    const Self = @This();

    pub fn init(data: []const u8, errorTolerance: u32) Self {
        var self = Self{ .data = data, .errorTolerance = errorTolerance };
        self.setDirection() catch unreachable;
        self.checkSafety() catch unreachable;
        return self;
    }

    fn setDirection(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var count_increasing: u32 = 0;
        var count_decreasing: u32 = 0;
        var prev_datum: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        while (token_data.next()) |datum| {
            const current_datum = try std.fmt.parseInt(u32, datum, 10);
            if (prev_datum < current_datum) {
                count_increasing += 1;
            } else if (prev_datum > current_datum) {
                count_decreasing += 1;
            }
            prev_datum = current_datum;
        }
        if (count_increasing > count_decreasing) {
            self.direction = .Increasing;
        } else if (count_decreasing > count_increasing) {
            self.direction = .Decreasing;
        } else self.direction = .Unsafe;
    }

    fn checkSafety_(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var prev_datum: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        switch (self.direction) {
            .Increasing => {
                while (token_data.next()) |datum| {
                    const current_datum = try std.fmt.parseInt(u32, datum, 10);
                    if (prev_datum >= current_datum or current_datum > prev_datum + 3) {
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_datum = current_datum;
                }
            },
            .Decreasing => {
                while (token_data.next()) |datum| {
                    const current_datum = try std.fmt.parseInt(u32, datum, 10);
                    if (prev_datum <= current_datum or prev_datum > current_datum + 3) {
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_datum = current_datum;
                }
            },
            .Unsafe => {
                self.safety = .Unsafe;
                return;
            },
        }
        self.safety = .Safe;
    }

    fn checkSafety(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var prev_datum: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        switch (self.direction) {
            .Increasing => {
                while (token_data.next()) |datum| {
                    const current_datum = try std.fmt.parseInt(u32, datum, 10);
                    if (prev_datum >= current_datum or current_datum > prev_datum + 3) {
                        if (self.errorTolerance > 0) {
                            self.errorTolerance -= 1;
                            continue;
                        }
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_datum = current_datum;
                }
            },
            .Decreasing => {
                while (token_data.next()) |datum| {
                    const current_datum = try std.fmt.parseInt(u32, datum, 10);
                    if (prev_datum <= current_datum or prev_datum > current_datum + 3) {
                        if (self.errorTolerance > 0) {
                            self.errorTolerance -= 1;
                            continue;
                        }
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_datum = current_datum;
                }
            },
            .Unsafe => {
                self.safety = .Unsafe;
                return;
            },
        }
        self.safety = .Safe;
    }
};

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
    const input_path = "./input/day02.txt";
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

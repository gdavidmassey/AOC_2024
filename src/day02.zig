const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

// 16 14 13 12 11 13 12 9 - day02.Direction.Decreasing
// 34 32 30 31 28 25 22 - day02.Direction.Decreasing
// 77 74 73 70 67 66 65 - day02.Direction.Decreasing
// This is returning safe when it should not

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
    safety: Safety = .Unsafe,
    direction: Direction = undefined,
    errorTolerance: u32,
    errorToleratedAsc: bool = false,
    errorToleratedDesc: bool = false,

    const Self = @This();

    pub fn init(data: []const u8, errorTolerance: u32) Self {
        var self = Self{ .data = data, .errorTolerance = errorTolerance };
        self.checkSafety() catch unreachable;
        return self;
    }

    fn setDirection(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var count_increasing: u32 = 0;
        var count_decreasing: u32 = 0;
        var prev_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        while (token_data.next()) |record| {
            const current_record = try std.fmt.parseInt(u32, record, 10);
            if (prev_record < current_record) {
                count_increasing += 1;
            } else if (prev_record > current_record) {
                count_decreasing += 1;
            }
            prev_record = current_record;
        }
        if (count_increasing > count_decreasing) {
            self.direction = .Increasing;
        } else if (count_decreasing > count_increasing) {
            self.direction = .Decreasing;
        } else self.direction = .Unsafe;
    }

    fn checkSafety_(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        var prev_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        switch (self.direction) {
            .Increasing => {
                while (token_data.next()) |record| {
                    const current_record = try std.fmt.parseInt(u32, record, 10);
                    if (prev_record >= current_record or current_record > prev_record + 3) {
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_record = current_record;
                }
            },
            .Decreasing => {
                while (token_data.next()) |record| {
                    const current_record = try std.fmt.parseInt(u32, record, 10);
                    if (prev_record <= current_record or prev_record > current_record + 3) {
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_record = current_record;
                }
            },
            .Unsafe => {
                self.safety = .Unsafe;
                return;
            },
        }
        self.safety = .Safe;
    }

    fn checkSafety__(self: *Self) !void {
        var token_data = std.mem.tokenizeAny(u8, self.data, " \t");
        const first_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        var prev_record: u32 = try std.fmt.parseInt(u32, token_data.next().?, 10);
        var drop_one_or_two: bool = false;
        switch (self.direction) {
            .Increasing => {
                var i: u32 = 0;
                if (compare(prev_record, first_record) != .Increasing) {
                    if (self.errorTolerance == 0) {
                        self.safety = .Unsafe;
                        return;
                    }
                    self.errorTolerance -= 1;
                }
                while (token_data.next()) |record| : (i += 1) {
                    //print("This is the result of compare(1,4) {}\n", .{compare(1, 4)});
                    std.debug.assert(compare(1, 4) == .Decreasing);
                    const current_record = try std.fmt.parseInt(u32, record, 10);
                    if (i > 0) drop_one_or_two = false;
                    const comp: bool = switch (drop_one_or_two) {
                        true => compare(current_record, prev_record) != .Increasing or compare(current_record, first_record) != .Increasing,
                        false => compare(current_record, prev_record) != .Increasing,
                    };
                    if (comp) {
                        if (self.errorTolerance > 0) {
                            if (i > 0) self.errorTolerance -= 1;
                            continue;
                        }
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_record = current_record;
                }
            },
            .Decreasing => {
                var i: u32 = 0;
                if (compare(prev_record, first_record) != .Decreasing) {
                    if (self.errorTolerance == 0) {
                        self.safety = .Unsafe;
                        return;
                    }
                    self.errorTolerance -= 1;
                    drop_one_or_two = true;
                }
                while (token_data.next()) |record| : (i += 1) {
                    const current_record = try std.fmt.parseInt(u32, record, 10);
                    if (i > 0) drop_one_or_two = false;
                    const comp: bool = switch (drop_one_or_two) {
                        true => compare(current_record, prev_record) != .Decreasing or compare(current_record, first_record) != .Decreasing,
                        false => compare(current_record, prev_record) != .Decreasing,
                    };
                    if (comp) {
                        if (self.errorTolerance > 0) {
                            if (i > 0) self.errorTolerance -= 1;
                            continue;
                        }
                        self.safety = .Unsafe;
                        return;
                    }
                    prev_record = current_record;
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
            switch (direction) {
                .Increasing => self.errorToleratedAsc = true,
                .Decreasing => self.errorToleratedDesc = true,
                .Unsafe => unreachable,
            }
            // print("{} {} {}\n", .{ first_record, prev_record, direction });
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
                switch (direction) {
                    .Increasing => self.errorToleratedAsc = true,
                    .Decreasing => self.errorToleratedDesc = true,
                    .Unsafe => return false,
                }
                // print("{} {} {} {}\n", .{ i, current_record, prev_record, direction });
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

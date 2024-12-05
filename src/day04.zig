const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;

const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_BUFFER_SIZE = 1048576;

pub fn day04(part: aoc.Part) !void {
    const input_path = "./input/day04.txt";
    const xmasMap: XmasMap = try .init(input_path);
    var xmas_count: u32 = 0;
    // print("{d} - {d}x{d}\n", .{ xmasMap.grid_string_len, xmasMap.width, xmasMap.height });

    for (xmasMap.grid_string, 0..) |c, i| {
        switch (part) {
            .Part_01 => {
                if (c == 'X') {
                    xmas_count += xmasMap.countXmas(i);
                }
            },
            .Part_02 => {
                if (c == 'A') {
                    xmas_count += xmasMap.countXMas(i);
                }
            },
        }
    }

    print("xmas count: {d}\n", .{xmas_count});
}

const XmasMap = struct {
    grid_string: [INPUT_BUFFER_SIZE]u8 = undefined,
    grid_string_len: usize = undefined,
    width: usize = undefined,
    height: usize = undefined,

    const Self = @This();

    pub fn init(input_path: []const u8) !Self {
        var self: Self = .{};
        var file = try std.fs.cwd().openFile(input_path, .{});
        defer file.close();
        self.grid_string_len = try file.read(&self.grid_string);
        self.width = std.mem.indexOf(u8, &self.grid_string, "\n").? + 1;
        self.height = self.grid_string_len / self.width;
        return self;
    }

    pub fn init_slice(input: []const u8) Self {
        var self: Self = .{};

        std.mem.copyForwards(u8, &self.grid_string, input);
        self.grid_string_len = std.mem.indexOf(u8, &self.grid_string, "\x00").?;
        self.width = std.mem.indexOf(u8, &self.grid_string, "\n").? + 1;
        self.height = self.grid_string_len / self.width;
        return self;
    }

    pub fn getXY(self: Self, i: usize) XY {
        return .{ .x = i % self.width, .y = i / self.width };
    }

    pub fn indexFromXY(self: Self, xy: XY) usize {
        return xy.y * self.width + xy.x;
    }

    pub fn countXmas(self: Self, i: usize) u32 {
        var sumXmas: u32 = 0;
        const directions: [8]Direction = [_]Direction{ .N, .S, .E, .W, .NE, .NW, .SE, .SW };

        for (directions) |direction| {
            if (self.checkXmas(i, direction)) sumXmas += 1;
        }
        return sumXmas;
    }

    pub fn countXMas(self: Self, i: usize) u32 {
        var sumXMas: u32 = 0;
        const directions: [2][2]Direction = [2][2]Direction{ [2]Direction{ .NE, .SW }, [2]Direction{ .NW, .SE } };

        outer: for (directions) |pair| {
            var checksum: u32 = 0;
            for (pair) |dir| {
                const j = self.checkDirection(i, dir) orelse continue :outer;
                checksum += self.grid_string[j];
            }
            if (checksum == 'M' + 'S') sumXMas += 1;
        }

        return if (sumXMas == 2) 1 else 0;
    }

    pub fn checkXmas(self: Self, i: usize, dir: Direction) bool {
        const xmas = "MAS";
        var j = i;
        // print("{c}\n", .{self.grid_string[i]});

        for (0..3) |k| {
            j = self.checkDirection(j, dir) orelse return false;
            if (self.grid_string[j] != xmas[k]) return false;
        }
        return true;
    }

    pub fn checkDirection(self: Self, i: usize, dir: Direction) ?usize {
        var xy = self.getXY(i);
        switch (dir) {
            .N => {
                if (xy.y > 0) xy.y -= 1 else return null;
            },
            .S => {
                if (xy.y < self.height) xy.y += 1 else return null;
            },
            .E => {
                if (xy.x < self.width) xy.x += 1 else return null;
            },
            .W => {
                if (xy.x > 0) xy.x -= 1 else return null;
            },
            .NE => {
                if (xy.y > 0) xy.y -= 1 else return null;
                if (xy.x < self.width) xy.x += 1 else return null;
            },
            .NW => {
                if (xy.y > 0) xy.y -= 1 else return null;
                if (xy.x > 0) xy.x -= 1 else return null;
            },
            .SE => {
                if (xy.y < self.height) xy.y += 1 else return null;
                if (xy.x < self.width) xy.x += 1 else return null;
            },
            .SW => {
                if (xy.y < self.height) xy.y += 1 else return null;
                if (xy.x > 0) xy.x -= 1 else return null;
            },
        }
        return self.indexFromXY(xy);
    }
};

const Direction = enum {
    N,
    S,
    E,
    W,
    NE,
    NW,
    SE,
    SW,
};

const XY = struct {
    x: usize,
    y: usize,
};

test "aoc day04 part1" {
    const input_path = "./input/day04_test.txt";
    const xmasMap: XmasMap = try .init(input_path);
    const part = aoc.Part.Part_01;
    var xmas_count: u32 = 0;
    print("{d} - {d}x{d}\n", .{ xmasMap.grid_string_len, xmasMap.width, xmasMap.height });

    for (xmasMap.grid_string, 0..) |c, i| {
        switch (part) {
            .Part_01 => {
                if (c == 'X') {
                    xmas_count += xmasMap.countXmas(i);
                }
            },
            .Part_02 => {
                if (c == 'A') {
                    xmas_count += xmasMap.countXMas(i);
                }
            },
        }
    }

    print("xmas count: {d}\n", .{xmas_count});
}

test "aoc day04 part2" {
    const input_path = "./input/day04_test.txt";
    const xmasMap: XmasMap = try .init(input_path);
    const part = aoc.Part.Part_02;
    var xmas_count: u32 = 0;
    print("{d} - {d}x{d}\n", .{ xmasMap.grid_string_len, xmasMap.width, xmasMap.height });

    for (xmasMap.grid_string, 0..) |c, i| {
        switch (part) {
            .Part_01 => {
                if (c == 'X') {
                    xmas_count += xmasMap.countXmas(i);
                }
            },
            .Part_02 => {
                if (c == 'A') {
                    xmas_count += xmasMap.countXMas(i);
                }
            },
        }
    }

    print("xmas count: {d}\n", .{xmas_count});
}

test "checkDirection" {
    const input = "123\n456\n789\n";
    const xmasMap: XmasMap = .init_slice(input);

    try std.testing.expectEqual(12, xmasMap.grid_string_len);
    try std.testing.expectEqual('1', xmasMap.grid_string[xmasMap.checkDirection(5, .NW).?]);
    try std.testing.expectEqual('2', xmasMap.grid_string[xmasMap.checkDirection(5, .N).?]);
    try std.testing.expectEqual('3', xmasMap.grid_string[xmasMap.checkDirection(5, .NE).?]);
    try std.testing.expectEqual('4', xmasMap.grid_string[xmasMap.checkDirection(5, .W).?]);
    try std.testing.expectEqual('6', xmasMap.grid_string[xmasMap.checkDirection(5, .E).?]);
    try std.testing.expectEqual('7', xmasMap.grid_string[xmasMap.checkDirection(5, .SW).?]);
    try std.testing.expectEqual('8', xmasMap.grid_string[xmasMap.checkDirection(5, .S).?]);
    try std.testing.expectEqual('9', xmasMap.grid_string[xmasMap.checkDirection(5, .SE).?]);
    try std.testing.expectEqual(12, xmasMap.grid_string_len);
    try std.testing.expectEqual(12, xmasMap.grid_string_len);
}

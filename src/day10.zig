const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_BUFFER_SIZE = 1048576;

pub fn day10(part: aoc.Part) !void {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day10.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var charMap: CharMap = try .init(input_path);
    try charMap.count_paths(allocator);

    print("Day 10 - {any}: ", .{part});
    switch (part) {
        .Part_01 => print("Total peaks reachable from trailhead: {d}", .{charMap.path_count}),
        .Part_02 => print("Total distinct paths from trailhead: {d}", .{charMap.distinct_path_count}),
    }
}

const CharMap = struct {
    grid_string: [INPUT_BUFFER_SIZE]u8 = undefined,
    grid_string_len: usize = undefined,
    width: usize = undefined,
    height: usize = undefined,
    path_count: u32 = 0,
    distinct_path_count: u32 = 0,

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

    pub fn clearPrint(self: Self) !void {
        const writer = std.io.getStdOut().writer();
        try writer.print("\x1B[2J\x1B[H", .{});
        // try writer.print("\x1B[96m#\x1B[0m", .{});
        try writer.print("{s}", .{self.grid_string});
    }

    pub fn getXY(self: *Self, i: usize) XY {
        return .{ .x = i % self.width, .y = i / self.width };
    }

    pub fn indexFromXY(self: *Self, xy: XY) usize {
        return xy.y * self.width + xy.x;
    }

    pub fn getChar(self: *Self, needle: u8) ?usize {
        for (self.grid_string, 0..) |c, i| {
            if (needle == c) {
                return i;
            }
        }
        return null;
    }

    pub fn checkDirection(self: *Self, i: usize, dir: Direction) ?usize {
        var xy = self.getXY(i);
        switch (dir) {
            .N => {
                if (xy.y > 0) xy.y -= 1 else return null;
            },
            .S => {
                if (xy.y < self.height - 1) xy.y += 1 else return null;
            },
            .E => {
                if (xy.x < self.width - 2) xy.x += 1 else return null;
            },
            .W => {
                if (xy.x > 0) xy.x -= 1 else return null;
            },
            .NE => {
                if (xy.y > 0) xy.y -= 1 else return null;
                if (xy.x < self.width - 2) xy.x += 1 else return null;
            },
            .NW => {
                if (xy.y > 0) xy.y -= 1 else return null;
                if (xy.x > 0) xy.x -= 1 else return null;
            },
            .SE => {
                if (xy.y < self.height - 1) xy.y += 1 else return null;
                if (xy.x < self.width - 2) xy.x += 1 else return null;
            },
            .SW => {
                if (xy.y < self.height - 1) xy.y += 1 else return null;
                if (xy.x > 0) xy.x -= 1 else return null;
            },
        }
        return self.indexFromXY(xy);
    }

    pub fn count_path_from_index(self: *Self, cur_index: usize, peak_map: *std.AutoHashMap(usize, bool)) !void {
        for ([4]Direction{ .N, .S, .E, .W }) |dir| {
            if (self.checkDirection(cur_index, dir)) |path_index| {
                if (self.grid_string[path_index] < '0' or self.grid_string[path_index] > '9' or self.grid_string[path_index] < self.grid_string[cur_index]) continue;

                if (self.grid_string[path_index] - self.grid_string[cur_index] == 1) {
                    if (self.grid_string[path_index] == '9') {
                        try peak_map.put(path_index, true);
                        self.distinct_path_count += 1;
                        continue;
                    }
                    try self.count_path_from_index(path_index, peak_map);
                }
            }
        }
    }

    pub fn count_paths(self: *Self, allocator: std.mem.Allocator) !void {
        for (self.grid_string, 0..) |c, i| {
            var trailpeak: std.AutoHashMap(usize, bool) = .init(allocator);
            if (c == '0') {
                try self.count_path_from_index(i, &trailpeak);
            }
            self.path_count += trailpeak.count();
        }
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

test "aoc day10 part1" {
    const input_path = "./input/day10_test2.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var charMap: CharMap = try .init(input_path);
    try charMap.count_paths(allocator);

    print("{d}\n", .{charMap.path_count});
}

test "aoc day10 part2" {}

test "checkDirection" {
    const input = "123\n456\n789\n";
    const charMap: CharMap = .init_slice(input);

    try std.testing.expectEqual(12, charMap.grid_string_len);
    try std.testing.expectEqual('1', charMap.grid_string[charMap.checkDirection(5, .NW).?]);
    try std.testing.expectEqual('2', charMap.grid_string[charMap.checkDirection(5, .N).?]);
    try std.testing.expectEqual('3', charMap.grid_string[charMap.checkDirection(5, .NE).?]);
    try std.testing.expectEqual('4', charMap.grid_string[charMap.checkDirection(5, .W).?]);
    try std.testing.expectEqual('6', charMap.grid_string[charMap.checkDirection(5, .E).?]);
    try std.testing.expectEqual('7', charMap.grid_string[charMap.checkDirection(5, .SW).?]);
    try std.testing.expectEqual('8', charMap.grid_string[charMap.checkDirection(5, .S).?]);
    try std.testing.expectEqual('9', charMap.grid_string[charMap.checkDirection(5, .SE).?]);
    try std.testing.expectEqual(12, charMap.grid_string_len);
}

const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_BUFFER_SIZE = 1048576;

pub fn day06(part: aoc.Part) !void {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day06.txt";
    const map_init: CharMap = try .init(input_path);
    var map = map_init;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const start: usize = map.getChar('^').?;

    print("Day 06 - {s}: ", .{part});
    switch (part) {
        .Part_01 => {
            var guard: Guard = try .init(.N, start, '^', allocator);
            try guard.patrol(&map);
            print("Patrol locations visited: {d}", .{guard.visited.count()});
        },
        .Part_02 => {
            var blocker: Guard = try .init(.N, start, '^', allocator);
            defer blocker.deinit();
            var loop_location: std.AutoHashMap(usize, bool) = .init(allocator);

            while (try blocker.quickstep(&map)) {
                map = map_init;
                blocker.placeObstacle(&map);
                var hare: Guard = .{ .direction = .N, .location = start, .char = '^' };
                var tortoise: Guard = .{ .direction = .N, .location = start, .char = '^' };
                defer {
                    blocker.pickupObstacle(&map);
                }
                while (try hare.quickstep(&map)) {
                    if (try hare.quickstep(&map)) {} else break;
                    if (hare.location == tortoise.location and hare.char == tortoise.char) {
                        try loop_location.put(blocker.location, true);
                        break;
                    }
                    if (try tortoise.quickstep(&map)) {} else break;
                }
            }
            print("Loop Count: {d}", .{loop_location.count()});
        },
    }
}

const Guard = struct {
    direction: Direction,
    location: usize,
    char: u8,
    visited: std.AutoHashMap(usize, u32) = undefined,

    const Self = @This();

    pub fn init(direction: Direction, location: usize, char: u8, allocator: std.mem.Allocator) !Self {
        var self: Self = .{ .direction = direction, .location = location, .char = char, .visited = .init(allocator) };
        try self.visited.put(location, 1);
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.visited.deinit();
    }

    pub fn turn(self: *Self) void {
        switch (self.direction) {
            .N => {
                self.char = '>';
                self.direction = Direction.E;
            },
            .S => {
                self.char = '<';
                self.direction = Direction.W;
            },
            .E => {
                self.char = 'v';
                self.direction = Direction.S;
            },
            .W => {
                self.char = '^';
                self.direction = Direction.N;
            },
            else => unreachable,
        }
    }

    pub fn patrol(self: *Self, map: *CharMap) !void {
        while (try self.step(map)) {}
    }

    pub fn step(self: *Self, map: *CharMap) !bool {
        const next_i: usize = if (map.checkDirection(self.location, self.direction)) |i| i else {
            return false;
        };
        // Test if guard is facing obstacle
        if (map.grid_string[next_i] == '#') {
            self.turn();
            map.grid_string[self.location] = self.char;
        } else {
            // Otherwise guard moves forward
            map.grid_string[self.location] = 'X';
            self.location = next_i;
            const result = try self.visited.getOrPut(self.location);
            if (!result.found_existing) {
                result.value_ptr.* = 0;
            }
            result.value_ptr.* += 0;
            map.grid_string[self.location] = self.char;
        }
        return true;
    }

    // No need to remember location
    pub fn quickstep(self: *Self, map: *CharMap) !bool {
        const next_i: usize = if (map.checkDirection(self.location, self.direction)) |i| i else {
            return false;
        };
        // Test if guard is facing obstacle
        if (map.grid_string[next_i] == '#') {
            self.turn();
        } else {
            // Otherwise guard moves forward
            self.location = next_i;
        }
        return true;
    }

    pub fn placeObstacle(self: *Self, map: *CharMap) void {
        map.grid_string[self.location] = '#';
    }

    pub fn pickupObstacle(self: *Self, map: *CharMap) void {
        map.grid_string[self.location] = self.char;
    }
};

const CharMap = struct {
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

    pub fn clearPrint(self: *Self) !void {
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

test "aoc day06 part1" {
    const input_path = "./input/day06_test.txt";
    const sleep_duration = 100;
    var charMap: CharMap = try .init(input_path);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var visited: std.AutoHashMap(usize, u32) = .init(allocator);
    const start: usize = charMap.getChar('^').?;

    var guard: Guard = try .init(.N, start, '^', allocator);
    guard.location = start;
    try visited.put(guard.location, 1);
    var visited_count: u32 = 0;
    var keys = visited.keyIterator();

    try charMap.clearPrint();
    while (keys.next()) |_| {
        visited_count += 1;
    }
    try stdout.print("Patrol locations visited: {d}\n", .{visited_count});
    std.time.sleep(std.time.ns_per_ms * sleep_duration);

    while (charMap.checkDirection(guard.location, guard.direction)) |i| {
        visited_count = 0;
        // Test if guard is facing obstacle
        if (charMap.grid_string[i] == '#') {
            guard.turn();
            charMap.grid_string[guard.location] = guard.char;
        } else {
            // Otherwise guard moves forward
            charMap.grid_string[guard.location] = 'X';
            guard.location = i;
            const result = try visited.getOrPut(guard.location);
            if (!result.found_existing) {
                result.value_ptr.* = 0;
            }
            result.value_ptr.* += 0;
            charMap.grid_string[guard.location] = guard.char;
        }

        // Print new location
        try charMap.clearPrint();
        keys = visited.keyIterator();
        while (keys.next()) |_| {
            visited_count += 1;
        }
        try stdout.print("w: {d}\nh:{d}\n", .{ charMap.width, charMap.height });
        try stdout.print("Patrol locations visited: {d}\n", .{visited_count});
        std.time.sleep(std.time.ns_per_ms * sleep_duration);
    }
}

test "aoc day06 part2" {
    const input_path = "./input/day06_test.txt";
    const sleep_duration = 100;
    const map_init: CharMap = try .init(input_path);
    var map = map_init;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const start: usize = map.getChar('^').?;

    var blocker: Guard = try .init(.N, start, '^', allocator);
    defer blocker.deinit();
    var loop_location: std.AutoHashMap(usize, bool) = .init(allocator);

    while (try blocker.quickstep(&map)) {
        var hare: Guard = try .init(.N, start, '^', allocator);
        var tortoise: Guard = try .init(.N, start, '^', allocator);
        map = map_init;
        blocker.placeObstacle(&map);
        defer {
            blocker.pickupObstacle(&map);
            hare.deinit();
            tortoise.deinit();
        }
        while (try hare.step(&map)) {
            std.time.sleep(std.time.ns_per_ms * sleep_duration);
            try map.clearPrint();
            if (try hare.step(&map)) {} else break;
            if (hare.location == tortoise.location and hare.char == tortoise.char) {
                try loop_location.put(blocker.location, true);
                break;
            }
            if (try tortoise.quickstep(&map)) {} else break;
        }
    }
    print("Loop Count: {d}\n", .{loop_location.count()});
}

test "checkDirection" {
    const input = "123\n456\n789\n";
    var charMap: CharMap = .init_slice(input);

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

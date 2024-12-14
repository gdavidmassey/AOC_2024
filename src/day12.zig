const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const stdout = std.io.getStdOut().writer();

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day12(part: aoc.Part) !void {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day12.txt";
    const allocator = std.heap.page_allocator;

    const map: aoc.CharMap = try .init(input_path);
    // try map.clearPrint();
    var region_map: std.AutoHashMap(usize, Crop) = .init(allocator);
    defer region_map.deinit();
    var visited: std.AutoHashMap(usize, bool) = .init(allocator);
    defer visited.deinit();

    // For each plot
    // if not visited add entry point to region hashmap. Recursively map out connected region.
    for (map.grid_string, 0..) |c, i| {
        if (c == '\n') continue;
        const plot_visited: bool = if (visited.get(i)) |result|
            result
        else
            false;
        if (plot_visited) continue;
        var crop: Crop = .{ .plot = 0, .fence = 0, .type = c };
        try searchPlot(i, &map, &crop, &visited);
        try region_map.put(i, crop);
    }

    var fence_cost: u32 = 0;
    var region_iter = region_map.valueIterator();
    while (region_iter.next()) |crop| {
        fence_cost += crop.plot * crop.fence;
        print("Crop: {c} - Count: {d} - Fence: {d}\n", .{ crop.type, crop.plot, crop.fence });
    }

    print("Day 12 - {any}: ", .{part});
    switch (part) {
        .Part_01 => print("Total cost of fencing: {d}", .{fence_cost}),
        .Part_02 => print("", .{}),
    }
}

test "aoc Day 12 Part 1" {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day12_test.txt";
    const allocator = std.heap.page_allocator;

    var map: aoc.CharMap = try .init(input_path);
    var region_map: std.AutoHashMap(usize, Crop) = .init(allocator);
    defer region_map.deinit();
    var visited: std.AutoHashMap(usize, bool) = .init(allocator);
    defer visited.deinit();

    // For each plot
    // if not visited add entry point to region hashmap. Recursively map out connected region.
    for (map.grid_string, 0..) |c, i| {
        if (c == '\n') continue;
        const plot_visited: bool = if (visited.get(i)) |result|
            result
        else
            false;
        if (plot_visited) continue;
        var crop: Crop = .{ .plot = 0, .fence = 0, .type = c };
        try searchPlot(i, &map, &crop, &visited);
        try region_map.put(i, crop);
    }

    var fence_cost: u32 = 0;
    var region_iter = region_map.valueIterator();
    while (region_iter.next()) |crop| {
        fence_cost += crop.plot * crop.fence;
        print("Crop: {c} - Count: {d} - Fence: {d}\n", .{ crop.type, crop.plot, crop.fence });
    }

    print("Total cost of fencing: {d}", .{fence_cost});
}

test "aoc Day 12 Part 2" {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day12_test.txt";
    const allocator = std.heap.page_allocator;

    var map: aoc.CharMap = try .init(input_path);
    var region_map: std.AutoHashMap(usize, Crop) = .init(allocator);
    defer region_map.deinit();
    var visited: std.AutoHashMap(usize, bool) = .init(allocator);
    defer visited.deinit();

    // For each plot
    // if not visited add entry point to region hashmap. Recursively map out connected region.
    for (map.grid_string, 0..) |c, i| {
        if (c == '\n') continue;
        const plot_visited: bool = if (visited.get(i)) |result|
            result
        else
            false;
        if (plot_visited) continue;
        var wall_checker: WallChecker = .{ .index = i, .direction = .N, .walls_seen = 0, .crop_char = c };
        try wall_checker.traverseWall(&map);
        var crop: Crop = .{ .plot = 0, .fence = 0, .type = c };
        try searchPlot(i, &map, &crop, &visited);
        crop.fence = wall_checker.walls_seen;
        try region_map.put(i, crop);
    }

    var fence_cost: u32 = 0;
    var region_iter = region_map.valueIterator();
    while (region_iter.next()) |crop| {
        fence_cost += crop.plot * crop.fence;
        print("Crop: {c} - Count: {d} - Fence: {d}\n", .{ crop.type, crop.plot, crop.fence });
    }

    print("Total cost of fencing: {d}", .{fence_cost});
}

const Crop = struct {
    plot: u32,
    fence: u32,
    type: u8,
};

// This function should map out the entirety of one connected crop type.
// Each connected plot should be added to visited.
// crop is updated and should be added to HashMap - hashed at arbitrary entry index.
// Function should recursively check each neigbouring plot of same crop type.
fn searchPlot(i: usize, map: *aoc.CharMap, crop: *Crop, visited: *std.AutoHashMap(usize, bool)) !void {
    crop.plot += 1;
    try visited.put(i, true);
    const directions: [4]aoc.Direction = [_]aoc.Direction{ .N, .S, .E, .W };
    for (directions) |direction| {
        const neighbour = map.checkDirection(i, direction);
        if (neighbour) |n| {
            const n_visited: bool = if (visited.get(n)) |result|
                result
            else
                false;
            // If same crop type skip fence
            // If not visited recursively check neighbouring plots
            if (map.grid_string[n] == crop.type) {
                if (!n_visited) try searchPlot(n, map, crop, visited);
                continue;
            }
        }
        // add fence if neighbour different crop or out of bounds
        crop.fence += 1;
    }
}

const WallChecker = struct {
    index: usize,
    direction: aoc.Direction,
    walls_seen: u32,
    starting_direction: aoc.Direction = .NW,
    starting_index: usize = 0,
    crop_char: u8 = '.',

    const Self = @This();

    pub fn turnRight(self: *Self) void {
        switch (self.direction) {
            .N => self.direction = .E,
            .S => self.direction = .W,
            .E => self.direction = .S,
            .W => self.direction = .N,
            else => unreachable,
        }
    }

    pub fn turnLeft(self: *Self) void {
        switch (self.direction) {
            .N => self.direction = .W,
            .S => self.direction = .E,
            .E => self.direction = .N,
            .W => self.direction = .S,
            else => unreachable,
        }
    }

    pub fn checkWallAhead(self: *const Self, map: *aoc.CharMap) bool {
        if (map.checkDirection(self.index, self.direction)) |neighbour| {
            // if (map.grid_string[self.index] == map.grid_string[neighbour]) return false;
            if (self.crop_char == map.grid_string[neighbour]) return false;
        }
        return true;
    }

    pub fn checkWallLeft(self: *const Self, map: *aoc.CharMap) bool {
        const check_direction: aoc.Direction = switch (self.direction) {
            .N => .W,
            .S => .E,
            .E => .N,
            .W => .S,
            else => unreachable,
        };
        if (map.checkDirection(self.index, check_direction)) |neighbour| {
            if (map.grid_string[self.index] == map.grid_string[neighbour]) return false;
        }
        return true;
    }

    pub fn step(self: *Self, map: *aoc.CharMap) void {
        const wall_ahead = self.checkWallAhead(map);
        const wall_left = self.checkWallLeft(map);
        map.grid_string_buffer[self.index] = self.crop_char;
        defer {
            map.grid_string_buffer[self.index] = '@';
        }

        if (wall_ahead and wall_left) {
            self.walls_seen += 1;
            if (self.walls_seen == 1) {
                self.starting_direction = self.direction;
                self.starting_index = self.index;
            }
            self.turnRight();
        } else if (!wall_ahead and wall_left) {
            self.index = map.checkDirection(self.index, self.direction).?;
        } else if (!wall_left) {
            self.walls_seen += 1;
            if (self.walls_seen == 1) {
                self.starting_direction = self.direction;
                self.starting_index = self.index;
            }
            self.turnLeft();
            self.index = map.checkDirection(self.index, self.direction).?;
        }
    }

    pub fn traverseWall(self: *Self, map: *aoc.CharMap) !void {
        while (self.direction != self.starting_direction and self.index != self.starting_index or self.walls_seen <= 1) {
            try map.clearPrint();
            print("{any}\n", .{self.direction});
            print("{any}\n", .{self.checkWallAhead(map)});
            std.time.sleep(1000000000);
            self.step(map);
        }
    }
};

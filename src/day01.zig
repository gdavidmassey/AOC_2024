const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn day01(part: aoc.Part) !void {
    const start_time = std.time.nanoTimestamp();
    defer {
        const end_time = std.time.nanoTimestamp();
        const elapsed = end_time - start_time;
        const elapsed_ms = @divFloor(elapsed, std.time.ns_per_ms);
        std.debug.print(" : {d}ms\n", .{elapsed_ms});
    }

    const input_path = "./input/day01.txt";
    var input: InputIterator = try .init(input_path);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var column1 = std.ArrayList(u32).init(allocator);
    var column2 = std.ArrayList(u32).init(allocator);
    defer column1.deinit();
    defer column2.deinit();

    while (input.next()) |line| {
        var column = std.mem.tokenizeAny(u8, line, " \t");
        try column1.append(try std.fmt.parseInt(u32, column.next().?, 10));
        try column2.append(try std.fmt.parseInt(u32, column.next().?, 10));
    }

    std.mem.sort(u32, column1.items[0..], {}, std.sort.asc(u32));
    std.mem.sort(u32, column2.items[0..], {}, std.sort.asc(u32));

    print("Day 01 - {s}: ", .{part});
    switch (part) {
        .Part_01 => {
            const sum_distance = try compareDistance(&column1, &column2);
            print("Total distance between pairs: {d}", .{sum_distance});
        },
        .Part_02 => {
            const sum_similarity = try compareSimilarity_(&column1, &column2);
            print("Total similarity score: {d}", .{sum_similarity});
        },
    }
}

fn compareDistance(column1: *std.ArrayList(u32), column2: *std.ArrayList(u32)) !u32 {
    var sum: u32 = 0;
    assert(column1.items.len == column2.items.len);
    for (column1.items, column2.items) |a, b| {
        sum += @intCast(@abs(@as(i32, @intCast(a)) - @as(i32, @intCast(b))));
    }
    return sum;
}

fn compareSimilarity(column1: *std.ArrayList(u32), column2: *std.ArrayList(u32)) !u32 {
    var sum: u32 = 0;
    assert(column1.items.len == column2.items.len);
    for (column1.items) |item| {
        sum += countElement(item, column2) * item;
    }
    return sum;
}

fn compareSimilarity_(column1: *std.ArrayList(u32), column2: *std.ArrayList(u32)) !u32 {
    var sum: u32 = 0;
    var col2_i: usize = 0;
    for (column1.items) |item| {
        var occurance_count: u32 = 0;
        while (column2.items[col2_i] <= item) {
            if (column2.items[col2_i] == item) {
                occurance_count += 1;
            }
            col2_i += 1;
            // if (col2_i >= column2.items.len) break;
        }
        sum += item * occurance_count;
    }
    return sum;
}

fn countElement(needle: u32, haystack: *std.ArrayList(u32)) u32 {
    var count: u32 = 0;
    for (haystack.items) |item| {
        if (needle == item) count += 1;
    }
    return count;
}

test "test aoc day01" {
    const input_path = "./input/day01_test.txt";
    var input: InputIterator = try .init(input_path);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var column1 = std.ArrayList(u32).init(allocator);
    var column2 = std.ArrayList(u32).init(allocator);
    defer column1.deinit();
    defer column2.deinit();

    while (input.next()) |line| {
        var column = std.mem.tokenizeAny(u8, line, " \t");
        try column1.append(try std.fmt.parseInt(u32, column.next().?, 10));
        try column2.append(try std.fmt.parseInt(u32, column.next().?, 10));
    }

    std.mem.sort(u32, column1.items[0..], {}, std.sort.asc(u32));
    std.mem.sort(u32, column2.items[0..], {}, std.sort.asc(u32));

    try std.testing.expectEqual(try compareDistance(&column1, &column2), 11);
    try std.testing.expectEqual(try compareSimilarity(&column1, &column2), 31);
}

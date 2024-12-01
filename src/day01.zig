const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = aoc.InputIterator;

const assert = std.debug.assert;
const print = std.debug.print;

pub fn day01(part: aoc.Part) !void {
    const input_path = "./input/day01.txt";
    var input: InputIterator = try .init(input_path);

    switch (part) {
        .Part_01 => {
            const sum_distance = try compareDistance(&input);
            print("Total distance between pairs: {d}\n", .{sum_distance});
        },
        .Part_02 => {
            const sum_similarity = try compareSimilarity(&input);
            print("Total similarity score: {d}\n", .{sum_similarity});
        },
    }
}

fn compareDistance(input: *InputIterator) !u32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var column1 = std.ArrayList(i32).init(allocator);
    var column2 = std.ArrayList(i32).init(allocator);
    defer column1.deinit();
    defer column2.deinit();

    while (input.next()) |line| {
        var column = std.mem.tokenizeAny(u8, line, " \t");
        try column1.append(try std.fmt.parseInt(i32, column.next().?, 10));
        try column2.append(try std.fmt.parseInt(i32, column.next().?, 10));
    }

    std.mem.sort(i32, column1.items[0..], {}, std.sort.asc(i32));
    std.mem.sort(i32, column2.items[0..], {}, std.sort.asc(i32));

    var sum: u32 = 0;

    assert(column1.items.len == column2.items.len);

    for (column1.items, column2.items) |a, b| {
        sum += @abs(a - b);
    }

    return sum;
}

fn compareSimilarity(input: *InputIterator) !u32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var column1 = std.ArrayList(u32).init(allocator);
    var column2 = std.ArrayList(u32).init(allocator);
    var freq_count = std.ArrayList(u32).init(allocator);
    defer column1.deinit();
    defer column2.deinit();
    defer freq_count.deinit();

    while (input.next()) |line| {
        var column = std.mem.tokenizeAny(u8, line, " \t");
        try column1.append(try std.fmt.parseInt(u32, column.next().?, 10));
        try column2.append(try std.fmt.parseInt(u32, column.next().?, 10));
    }

    std.mem.sort(u32, column1.items[0..], {}, std.sort.asc(u32));
    std.mem.sort(u32, column2.items[0..], {}, std.sort.asc(u32));

    var sum: u32 = 0;

    assert(column1.items.len == column2.items.len);

    for (column1.items) |item| {
        sum += countElement(item, &column2) * item;
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

    try std.testing.expectEqual(try compareDistance(&input), 11);
}

test "test aoc day02" {
    const input_path = "./input/day01_test.txt";
    var input: InputIterator = try .init(input_path);

    try std.testing.expectEqual(try compareSimilarity(&input), 31);
}

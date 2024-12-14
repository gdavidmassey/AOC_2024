const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day05(part: aoc.Part) !void {
    const input_path = "./input/day05.txt";
    var input: InputIterator = try .init_(input_path);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer assert(gpa.deinit() == .ok);
    defer arena.deinit();

    const allocator = arena.allocator();
    var myDic: OrdDict = .init(allocator);

    while (input.next_s()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        try myDic.add(try Ord.parse(line));
    }

    var sum_p1: u32 = 0;
    var sum_p2: u32 = 0;
    while (input.next_s()) |line| {
        myDic.current_report = try parseReport(line, allocator);
        defer myDic.current_report.deinit();
        if (isOrdered(myDic.current_report, &myDic)) {
            sum_p1 += myDic.current_report.items[myDic.current_report.items.len / 2];
        } else {
            std.mem.sort(u32, myDic.current_report.items, &myDic, OrdDict.lessThan);
            sum_p2 += myDic.current_report.items[myDic.current_report.items.len / 2];
        }
    }
    print("Day 05 - {s}: ", .{part});
    switch (part) {
        .Part_01 => print("Checksum of ordered reports: {d}\n", .{sum_p1}),
        .Part_02 => print("Checksum of unordered reports: {d}\n", .{sum_p2}),
    }
}

pub fn parseReport(s: []const u8, allocator: std.mem.Allocator) !ArrayList(u32) {
    var tokens = std.mem.tokenizeAny(u8, s, ",");
    var report: ArrayList(u32) = .init(allocator);
    while (tokens.next()) |tok| {
        const number = try std.fmt.parseInt(u32, tok, 10);
        try report.append(number);
    }
    return report;
}

pub fn isOrdered(report: ArrayList(u32), context: *OrdDict) bool {
    const report_len = report.items.len;
    for (0..report_len - 1) |i| {
        if (!context.lessThan(report.items[i], report.items[i + 1])) return false;
    }
    return true;
}

pub fn comparePage() void {}

const Ord = struct {
    a: u32,
    b: u32,

    const Self = @This();

    const OrdError = error{
        ParseError,
    };

    pub fn parse(s: []const u8) OrdError!Ord {
        var tok = std.mem.tokenizeAny(u8, s, "|");
        return .{ .a = std.fmt.parseInt(u32, tok.next() orelse {
            return OrdError.ParseError;
        }, 10) catch {
            return OrdError.ParseError;
        }, .b = std.fmt.parseInt(u32, tok.next() orelse {
            return OrdError.ParseError;
        }, 10) catch {
            return OrdError.ParseError;
        } };
    }
};

const OrdDict = struct {
    dict: AutoHashMap(u32, ArrayList(u32)),
    allocator: std.mem.Allocator,
    current_report: ArrayList(u32) = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .dict = AutoHashMap(u32, ArrayList(u32)).init(allocator), .allocator = allocator };
    }

    pub fn add(self: *Self, ord: Ord) !void {
        const gpr = try self.dict.getOrPut(ord.a);
        if (!gpr.found_existing) {
            gpr.value_ptr.* = ArrayList(u32).init(self.dict.allocator);
            try gpr.value_ptr.*.append(ord.b);
        } else {
            try gpr.value_ptr.*.append(ord.b);
        }
    }

    pub fn get(self: *Self, k: u32) ?*ArrayList(u32) {
        return self.dict.getPtr(k);
    }

    pub fn lessThan(self: *Self, a: u32, b: u32) bool {
        var children: ArrayList(u32) = .init(self.allocator);
        var visited: AutoHashMap(u32, bool) = .init(self.allocator);
        defer visited.deinit();
        defer children.deinit();

        _ = children.append(a) catch {};

        while (children.items.len > 0) {
            const child_item = children.pop();

            const result = visited.getOrPut(child_item) catch unreachable;
            if (result.found_existing) {
                if (result.key_ptr.* == a) {
                    continue;
                }
                continue;
            }
            result.value_ptr.* = true;
            const b_list = self.get(child_item) orelse {
                continue;
            };
            blist: for (b_list.items) |b_| {
                if (b == b_) return true;
                var rule_is_valid = false;
                item: for (self.current_report.items) |item| {
                    if (b_ == item) {
                        rule_is_valid = true;
                        break :item;
                    }
                }
                if (!rule_is_valid) continue :blist;
                _ = children.append(b_) catch {};
            }
        }
        return false;
    }
};

test "testing day05 part1" {
    const input_path = "./input/day05_test.txt";
    var input: InputIterator = try .init_(input_path);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer assert(gpa.deinit() == .ok);
    defer arena.deinit();

    const allocator = arena.allocator();
    var myDic: OrdDict = .init(allocator);

    while (input.next_s()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        try myDic.add(try Ord.parse(line));
    }

    var sum_p1: u32 = 0;
    var sum_p2: u32 = 0;
    while (input.next_s()) |line| {
        myDic.current_report = try parseReport(line, allocator);
        defer myDic.current_report.deinit();
        if (isOrdered(myDic.current_report, &myDic)) {
            sum_p1 += myDic.current_report.items[myDic.current_report.items.len / 2];
        } else {
            std.mem.sort(u32, myDic.current_report.items, &myDic, OrdDict.lessThan);
            sum_p2 += myDic.current_report.items[myDic.current_report.items.len / 2];
        }
    }
    print("Checksum of ordered reports: {d}\n", .{sum_p1});
}

test "testing day05 part2" {
    const input_path = "./input/day05_test.txt";
    var input: InputIterator = try .init_(input_path);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer assert(gpa.deinit() == .ok);
    defer arena.deinit();

    const allocator = arena.allocator();
    var myDic: OrdDict = .init(allocator);

    while (input.next_s()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        try myDic.add(try Ord.parse(line));
    }

    var sum_p1: u32 = 0;
    var sum_p2: u32 = 0;
    while (input.next_s()) |line| {
        myDic.current_report = try parseReport(line, allocator);
        defer myDic.current_report.deinit();
        if (isOrdered(myDic.current_report, &myDic)) {
            // print("{any}\n", .{report.items});
            sum_p1 += myDic.current_report.items[myDic.current_report.items.len / 2];
        } else {
            std.mem.sort(u32, myDic.current_report.items, &myDic, OrdDict.lessThan);
            // print("{any}\n", .{report.items});
            sum_p2 += myDic.current_report.items[myDic.current_report.items.len / 2];
        }
    }
    print("Checksum of unordered reports: {d}\n", .{sum_p2});
}

test "parseOrd" {
    const myOrd = try Ord.parse("45|342");
    try std.testing.expectEqual(45, myOrd.a);
    try std.testing.expectEqual(342, myOrd.b);
}

// test "MyDict:add" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const allocator = gpa.allocator();
//     var my_dict: OrdDict = .init(allocator);
//     try my_dict.add(try Ord.parse("234|23"));
//     try my_dict.add(try Ord.parse("234|233"));
//     try my_dict.add(try Ord.parse("234|2153"));
//     try my_dict.add(try Ord.parse("233|127"));
//     try my_dict.add(try Ord.parse("233|92"));
//     try my_dict.add(try Ord.parse("233|356"));
//     try my_dict.add(try Ord.parse("92|709"));
//     try std.testing.expect(my_dict.lessThan(234, 233));
//     try std.testing.expect(my_dict.lessThan(234, 709));
//     const report1 = try parseReport("234,233,92,709", allocator);
//     defer report1.deinit();
//     const report2 = try parseReport("234,92,709", allocator);
//     defer report2.deinit();
//     const report3 = try parseReport("233,233,233,92,709", allocator);
//     defer report3.deinit();
//     const report4 = try parseReport("234,233,952,709", allocator);
//     defer report4.deinit();
//     try std.testing.expect(isOrdered(report1, &my_dict));
//     try std.testing.expect(isOrdered(report2, &my_dict));
//     try std.testing.expect(!isOrdered(report3, &my_dict));
//     try std.testing.expect(!isOrdered(report4, &my_dict));
//     try std.testing.expect(my_dict.lessThan(92, 709));
// }
//
test "parseReport" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const report = "12,34,65,3245,34";

    print("{any}\n", .{(try parseReport(report, allocator)).items});
}

test "Sorting" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var my_dict: OrdDict = .init(allocator);
    try my_dict.add(try Ord.parse("1|2"));
    try my_dict.add(try Ord.parse("2|3"));
    try my_dict.add(try Ord.parse("3|4"));
    try my_dict.add(try Ord.parse("1|4"));

    var kit = my_dict.dict.keyIterator();
    while (kit.next()) |key| {
        const value = my_dict.dict.get(key.*).?;
        print("K: {d} - {any}\n", .{ key.*, value.items });
    }
    my_dict.current_report = try parseReport("3,2,1,4", allocator);
    defer my_dict.current_report.deinit();
    print("Current Report: {any}\n", .{my_dict.current_report.items});
    try std.testing.expect(my_dict.lessThan(1, 2));
    try std.testing.expect(my_dict.lessThan(1, 3));
    try std.testing.expect(!my_dict.lessThan(3, 1));
    try std.testing.expect(!isOrdered(my_dict.current_report, &my_dict));
    std.mem.sort(u32, my_dict.current_report.items, &my_dict, OrdDict.lessThan);
    print("Current Report: {any}\n", .{my_dict.current_report.items});
    try std.testing.expect(isOrdered(my_dict.current_report, &my_dict));
}

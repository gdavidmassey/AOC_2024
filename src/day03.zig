const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;

const print = std.debug.print;

pub fn day03(part: aoc.Part) void {
    _ = part;
}

const Lexer = struct {
    data: []const u8,
    index: usize = 0,
    read_ahead: usize = 0,
    ch: u8 = undefined,

    const Self = @This();

    pub fn init(data: []const u8) Self {
        return .{ .data = data };
    }

    fn readChar(self: *Self) void {
        if (self.read_ahead >= self.data.len) {
            self.ch = 0;
        } else {
            self.ch = self.data[self.read_ahead];
        }
    }

    const TokenType = enum {
        Mul,
        Number,
        LParen,
        RParen,
        Comma,
        Corrupt,
    };

    const Token = struct {
        type: TokenType,
        data: []const u8,
    };
};

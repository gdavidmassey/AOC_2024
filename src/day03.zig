const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;

const print = std.debug.print;

pub fn day03(part: aoc.Part) !void {
    const input_path = "./input/day03.txt";
    var input_buffer: [1048576]u8 = undefined;
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();
    const input_bufLen = try file.read(&input_buffer);

    var sum: u32 = 0;

    const l = Lexer.init(input_buffer[0..input_bufLen]);
    var p: Parser = .init(l);
    switch (part) {
        .Part_01 => {
            while (p.lexer.ch != 0) {
                sum += (p.parseMul_p1() catch continue) orelse continue;
            }
        },
        .Part_02 => {
            while (p.lexer.ch != 0) {
                p.parseToken();
            }
            sum = p.sum;
        },
    }
    print("Day 03 - {s}: ", .{part});
    print("Sum of valid mul(a,b) operations: {d}\n", .{sum});
}

const Lexer = struct {
    data: []const u8,
    index: usize = 0,
    read_ahead: usize = 0,
    ch: u8 = 0,

    const Self = @This();

    pub fn init(data: []const u8) Self {
        var l: Self = .{ .data = data };
        l.nextChar();
        return l;
    }

    const LexerError = error{
        EOF,
    };

    fn nextChar(self: *Self) void {
        if (self.read_ahead >= self.data.len) {
            self.ch = 0;
        } else {
            self.ch = self.data[self.read_ahead];
        }
        self.index = self.read_ahead;
        self.read_ahead += 1;
    }

    fn readChar(self: *Self) []const u8 {
        const start = self.index;
        self.nextChar();
        return self.data[start..self.index];
    }

    pub fn peekChar(self: *Self) u8 {
        var peek: u8 = undefined;
        if (self.read_ahead >= self.data.len) {
            peek = 0;
        } else {
            peek = self.data[self.read_ahead];
        }
        return peek;
    }

    fn nextToken(self: *Self) Token {
        const tok: Token = switch (self.ch) {
            '(' => Token.init(.LParen, self.readChar()),
            ')' => Token.init(.RParen, self.readChar()),
            ',' => Token.init(.Comma, self.readChar()),
            '\n' => newline: {
                self.nextChar();
                break :newline self.nextToken();
            },
            0 => return .{ .type = .EOF, .data = "" },
            else => if (self.isDigit()) Token.init(.Number, self.readNumber()) else if (self.isLetter())
                self.readIdentifier()
            else
                Token.init(.Corrupt, self.readChar()),
        };
        return tok;
    }

    pub fn readIdentifier(self: *Self) Token {
        const start = self.index;
        while (self.isLetter()) self.nextChar();

        const tokenType = std.meta.stringToEnum(Token.TokenType, self.data[start..self.index]) orelse {
            self.index = start;
            self.read_ahead = start + 1;
            self.nextChar();
            return Token.init(.Corrupt, self.data[start..self.index]);
        };

        return switch (tokenType) {
            .mul => Token.init(tokenType, self.data[start..self.index]),
            .do => Token.init(tokenType, self.data[start..self.index]),
            .@"don't" => Token.init(tokenType, self.data[start..self.index]),
            else => Token.init(.Identifier, self.data[start..self.index]),
        };
    }

    pub fn readNumber(self: *Self) []const u8 {
        const start = self.index;
        while (self.isDigit()) self.nextChar();
        return self.data[start..self.index];
    }

    pub fn isDigit(self: *Self) bool {
        return '0' <= self.ch and self.ch <= '9';
    }

    pub fn isLetter(self: *Self) bool {
        // return 'a' <= self.ch and self.ch <= 'z' or 'A' <= self.ch and self.ch <= 'Z' or self.ch == '\'' or self.ch == '_';
        return switch (self.ch) {
            'm' => true,
            'u' => true,
            'l' => true,
            'd' => true,
            'o' => true,
            'n' => true,
            't' => true,
            '\'' => true,
            else => false,
        };
    }
};

const Token = struct {
    type: TokenType,
    data: []const u8,

    const Self = @This();

    const TokenType = enum {
        EOF,
        Identifier,
        mul,
        do,
        @"don't",
        Number,
        LParen,
        RParen,
        Comma,
        Corrupt,
    };
    fn init(t: TokenType, d: []const u8) Self {
        return .{ .type = t, .data = d };
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s}: \"{s}\"", .{ @tagName(self.type), self.data });
    }
};

const Parser = struct {
    lexer: Lexer,
    token: Token = undefined,
    mul: bool = true,
    sum: u32 = 0,

    const Self = @This();

    pub fn init(lexer: Lexer) Self {
        var l: Self = .{ .lexer = lexer };
        l.nextToken();
        return l;
    }

    pub fn parseToken(self: *Self) void {
        self.nextToken();
        switch (self.token.type) {
            .mul => if (self.mul) self.parseMul() catch return,
            .do => self.parseDo(),
            .@"don't" => self.parseDont(),
            else => return,
        }
    }

    pub fn parseDo(self: *Self) void {
        if (self.token.type != Token.TokenType.do) return;
        self.nextToken();
        if (self.token.type != Token.TokenType.LParen) return;
        self.nextToken();
        if (self.token.type != Token.TokenType.RParen) return;
        self.mul = true;
    }

    pub fn parseDont(self: *Self) void {
        if (self.token.type != Token.TokenType.@"don't") return;
        self.nextToken();
        if (self.token.type != Token.TokenType.LParen) return;
        self.nextToken();
        if (self.token.type != Token.TokenType.RParen) return;
        self.mul = false;
    }

    pub fn parseMul_p1(self: *Self) !?u32 {
        while (self.token.type != Token.TokenType.mul) {
            self.nextToken();
            if (self.token.type == .EOF) return null;
        }
        self.nextToken();
        if (self.token.type != Token.TokenType.LParen) return null;
        self.nextToken();
        if (self.token.type != Token.TokenType.Number) return null;
        const a: u32 = try std.fmt.parseInt(u32, self.token.data, 10);
        self.nextToken();
        if (self.token.type != Token.TokenType.Comma) return null;
        self.nextToken();
        if (self.token.type != Token.TokenType.Number) return null;
        const b: u32 = try std.fmt.parseInt(u32, self.token.data, 10);
        self.nextToken();
        if (self.token.type != Token.TokenType.RParen) return null;
        return a * b;
    }

    pub fn parseMul(self: *Self) !void {
        self.nextToken();
        if (self.token.type != Token.TokenType.LParen) return;
        self.nextToken();
        if (self.token.type != Token.TokenType.Number) return;
        const a: u32 = try std.fmt.parseInt(u32, self.token.data, 10);
        self.nextToken();
        if (self.token.type != Token.TokenType.Comma) return;
        self.nextToken();
        if (self.token.type != Token.TokenType.Number) return;
        const b: u32 = try std.fmt.parseInt(u32, self.token.data, 10);
        self.nextToken();
        if (self.token.type != Token.TokenType.RParen) return;
        self.sum += a * b;
    }

    pub fn nextToken(self: *Self) void {
        self.token = self.lexer.nextToken();
    }
};

test "aoc day03 part1" {
    const input_path = "./input/day03_test.txt";
    var input: InputIterator = try .init(input_path);
    var sum: u32 = 0;

    while (input.next()) |line| {
        const l = Lexer.init(line);
        var p: Parser = .init(l);
        while (p.lexer.ch != 0) {
            sum += (p.parseMul_p1() catch continue) orelse continue;
        }
    }

    try std.testing.expectEqual(161, sum);
}

test "aoc day03 part2" {
    const input_path = "./input/day03_test_p2.txt";
    var input: InputIterator = try .init(input_path);
    var sum: u32 = 0;

    while (input.next()) |line| {
        const l = Lexer.init(line);
        var p: Parser = .init(l);
        while (p.lexer.ch != 0) {
            p.parseToken();
        }
        sum += p.sum;
    }

    try std.testing.expectEqual(48, sum);
}

// test "Testing Lexer" {
//     const input = "(4)123mul324$23don't4%@fizz_buzz!@#@";
//     var l = Lexer.init(input);
//     while (l.ch != 0) {
//         print("{}\n", .{l.nextToken()});
//     }
// }
//
// test "Tesing Parser" {
//     const input = "(4)123mul324$23don't4%mul(12,3)@fizz_buzz!@#@";
//     const l = Lexer.init(input);
//     var p: Parser = .init(l);
//     var sum: u32 = 0;
//     print("{c}\n", .{p.lexer.ch});
//     while (p.lexer.ch != 0) {
//         print("{c}\n", .{p.lexer.ch});
//         sum += (p.parseMul_p1() catch continue) orelse continue;
//     }
//     print("sum of mults is {d}\n", .{sum});
// }

const std = @import("std");

pub const Part = enum {
    Part_01,
    Part_02,
};

pub const InputIterator = struct {
    _buffer: [4048576]u8 = undefined,
    _bufLen: usize = 0,
    lines: std.mem.TokenIterator(u8, .any) = undefined,

    const Self = @This();

    pub fn init(path: []const u8) !Self {
        var self = Self{};
        for (self._buffer, 0..) |_, i| {
            self._buffer[i] = '\x00';
        }
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        self._bufLen = try file.read(&self._buffer);
        self.tokenizeLines();
        return self;
    }

    pub fn tokenizeLines(self: *Self) void {
        self.lines = std.mem.tokenizeAny(u8, &self._buffer, "\n\x00");
    }

    pub fn next(self: *Self) ?[]const u8 {
        if (@intFromPtr(&self.lines.buffer[0]) != @intFromPtr(&self._buffer[0])) self.lines.buffer = self._buffer[0..];
        if (self.lines.index >= self._bufLen - 1) {
            return null;
        }
        const result = self.lines.peek() orelse {
            return null;
        };
        // std.debug.print("{d} - ", .{result.len});
        if (result.len == 0) return null;

        return self.lines.next();
    }

    pub fn reset(self: *Self) void {
        self.lines.reset();
    }
};

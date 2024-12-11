const std = @import("std");

pub fn check_or_create_file(dir: std.fs.Dir, file_name: []const u8) !void {
    var file = dir.openFile(file_name, .{}) catch |err| blk: {
        switch (err) {
            std.fs.File.OpenError.FileNotFound => break :blk null,
            else => return err,
        }
    };

    if (file == null) {
        _ = try dir.createFile(file_name, .{});
    } else {
        file.?.close();
    }
}

pub const Part = enum {
    Part_01,
    Part_02,
};

pub const InputIterator = struct {
    _buffer: [1048576]u8 = undefined,
    _bufLen: usize = 0,
    lines: std.mem.TokenIterator(u8, .any) = undefined,
    split: std.mem.SplitIterator(u8, .any) = undefined,

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

    pub fn init_(path: []const u8) !Self {
        var self = Self{};
        for (self._buffer, 0..) |_, i| {
            self._buffer[i] = '\x00';
        }
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        self._bufLen = try file.read(&self._buffer);
        _ = self.splitLines();
        return self;
    }

    pub fn tokenizeLines(self: *Self) void {
        self.lines = std.mem.tokenizeAny(u8, &self._buffer, "\n\x00");
    }

    pub fn splitLines(self: *Self) void {
        self.split = std.mem.splitAny(u8, &self._buffer, "\n\x00");
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

    pub fn next_s(self: *Self) ?[]const u8 {
        if (@intFromPtr(&self.split.buffer[0]) != @intFromPtr(&self._buffer[0])) self.split.buffer = self._buffer[0..];
        if (self.split.index.? >= self._bufLen - 1) {
            return null;
        }
        // const result = self.split.peek() orelse {
        //     return null;
        // };
        // // std.debug.print("{d} - ", .{result.len});
        // if (result.len == 0) return null;

        return self.split.next();
    }

    pub fn reset(self: *Self) void {
        self.lines.reset();
    }
};

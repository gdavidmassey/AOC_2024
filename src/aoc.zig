const std = @import("std");

const INPUT_BUFFER_SIZE = 1048576;

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

    pub fn format(self: Part, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const str_fmt = switch (self) {
            .Part_01 => "Part 1",
            .Part_02 => "Part 2",
        };

        try writer.print("{s}", .{str_fmt});
    }
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
        if (result.len == 0) return null;

        return self.lines.next();
    }

    pub fn next_s(self: *Self) ?[]const u8 {
        if (@intFromPtr(&self.split.buffer[0]) != @intFromPtr(&self._buffer[0])) self.split.buffer = self._buffer[0..];
        if (self.split.index.? >= self._bufLen - 1) {
            return null;
        }

        return self.split.next();
    }

    pub fn reset(self: *Self) void {
        self.lines.reset();
    }
};

pub const CharMap = struct {
    grid_string_buffer: [INPUT_BUFFER_SIZE]u8 = undefined,
    grid_string: []const u8 = undefined,
    grid_string_len: usize = undefined,
    width: usize = undefined,
    height: usize = undefined,

    const Self = @This();

    pub fn init(input_path: []const u8) !Self {
        var self: Self = .{};
        var file = try std.fs.cwd().openFile(input_path, .{});
        defer file.close();
        self.grid_string_len = try file.read(&self.grid_string_buffer);
        self.grid_string = self.grid_string_buffer[0..self.grid_string_len];
        self.width = std.mem.indexOf(u8, &self.grid_string_buffer, "\n").? + 1;
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

    pub fn clearPrint(self: *const Self) !void {
        const writer = std.io.getStdOut().writer();
        try writer.print("\x1B[2J\x1B[H", .{});
        // try writer.print("\x1B[96m#\x1B[0m", .{});
        try writer.print("{s}", .{self.grid_string_buffer});
    }

    pub fn getXY(self: *const Self, i: usize) XY {
        return .{ .x = i % self.width, .y = i / self.width };
    }

    pub fn indexFromXY(self: *const Self, xy: XY) usize {
        return xy.y * self.width + xy.x;
    }

    pub fn getChar(self: *const Self, needle: u8) ?usize {
        for (self.grid_string, 0..) |c, i| {
            if (needle == c) {
                return i;
            }
        }
        return null;
    }

    pub fn checkDirection(self: *const Self, i: usize, dir: Direction) ?usize {
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

pub const Direction = enum {
    N,
    S,
    E,
    W,
    NE,
    NW,
    SE,
    SW,
};

pub const XY = struct {
    x: usize,
    y: usize,
};

const std = @import("std");
const aoc = @import("aoc.zig");
const InputIterator = @import("aoc.zig").InputIterator;
const Md5 = std.crypto.hash.Md5;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn day05(part: aoc.Part) !void {
    const input_path = "./input/2016_Day05.txt";
    var input: InputIterator = try .init(input_path);

    const door_id = input.next().?;
    // const door_id = "abc";
    var password: [8]u8 = [_]u8{ '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00', '\x00' };

    var i: u32 = 1;
    var pw_char_i: u8 = 0;
    while (i < 92319590) : (i += 1) {
        var door_id_buf: [128]u8 = undefined;
        const door_id_numbered = try std.fmt.bufPrint(&door_id_buf, "{s}{d}", .{ door_id, i });
        // const door_id_numbered = door_id_buf[0..door_id_len];
        var md5 = Md5.init(.{});
        md5.update(door_id_numbered);
        var result: [16]u8 = undefined;
        md5.final(&result);
        if (checkHash(&result)) {
            switch (part) {
                .Part_01 => {
                    _ = try std.fmt.bufPrint(password[pw_char_i..], "{x}", .{result[2]});
                    pw_char_i += 1;
                },
                .Part_02 => {
                    var hex_3: [2]u8 = undefined;
                    var hex_2: [2]u8 = undefined;
                    _ = try std.fmt.bufPrint(&hex_3, "{x:0>2}", .{result[3]});
                    _ = try std.fmt.bufPrint(&hex_2, "{x:0>2}", .{result[2]});
                    if (hex_2[1] >= '0' and hex_2[1] <= '7') {
                        // print("{c}\n", .{hex_2[1]});
                        const pw_char_i_p2 = try std.fmt.parseInt(usize, hex_2[1..2], 10);
                        if (password[pw_char_i_p2] == '\x00') {
                            password[pw_char_i_p2] = hex_3[0];
                            pw_char_i += 1;
                        }
                    }
                    // print("{s} {s} - {x:0>2}\n", .{ hex_2, hex_3, result });
                },
            }
            // print("{x} - {} {d}\n", .{ result, checkHash(&result), i });
        }
        if (pw_char_i == 8) break;
        // if (i == 3231929) {
        //     print("323 - {s} - {d}\n", .{ door_id_numbered, door_id_numbered.len });
        //     print("{x}\n", .{result});
        // }
    }
    print("North Pole Object Storage Password: {s}\n", .{password});
}

fn checkHash(hash: []u8) bool {
    if (hash[2] > 15) return false;
    for (0..2) |i| {
        if (hash[i] != 0) {
            return false;
        }
    }
    return true;
}

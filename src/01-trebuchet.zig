const std = @import("std");

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/01.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    //iterate each line an add up the numbers
    var total: u32 = 0;
    while (lines.next()) |line| {
        const value = try get_number(allocator, line);
        std.debug.print("line: {s} - {d}\n", .{ line, value });
        total += value;
    }

    std.debug.print("Total: {d}\n", .{total});
}

//Get the first and last number concatenated as an integer for the given line
fn get_number(allocator: std.mem.Allocator, line: []const u8) !u32 {
    const digits = try extract_digits(allocator, line);
    defer allocator.free(digits);

    var number: u32 = digits[0] * 10;
    number += digits[digits.len - 1];

    return number;
}

//Find all the numbers in the line
fn extract_digits(allocator: std.mem.Allocator, line: []const u8) ![]u32 {
    var digits = std.ArrayList(u32).init(allocator);
    defer digits.deinit();

    const numbers = [_][]const u8{ "1", "2", "3", "4", "5", "6", "7", "8", "9", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

    var i: u32 = 0;
    while (i < line.len) : (i += 1) {
        const slice = line[i..];
        for (numbers) |m| {
            const matches = std.mem.startsWith(u8, slice, m);
            if (matches) {
                if (std.mem.eql(u8, m, "1")) try digits.append(1);
                if (std.mem.eql(u8, m, "2")) try digits.append(2);
                if (std.mem.eql(u8, m, "3")) try digits.append(3);
                if (std.mem.eql(u8, m, "4")) try digits.append(4);
                if (std.mem.eql(u8, m, "5")) try digits.append(5);
                if (std.mem.eql(u8, m, "6")) try digits.append(6);
                if (std.mem.eql(u8, m, "7")) try digits.append(7);
                if (std.mem.eql(u8, m, "8")) try digits.append(8);
                if (std.mem.eql(u8, m, "9")) try digits.append(9);
                if (std.mem.eql(u8, m, "one")) try digits.append(1);
                if (std.mem.eql(u8, m, "two")) try digits.append(2);
                if (std.mem.eql(u8, m, "three")) try digits.append(3);
                if (std.mem.eql(u8, m, "four")) try digits.append(4);
                if (std.mem.eql(u8, m, "five")) try digits.append(5);
                if (std.mem.eql(u8, m, "six")) try digits.append(6);
                if (std.mem.eql(u8, m, "seven")) try digits.append(7);
                if (std.mem.eql(u8, m, "eight")) try digits.append(8);
                if (std.mem.eql(u8, m, "nine")) try digits.append(9);
                break;
            }
        }
    }

    const slice = try digits.toOwnedSlice();
    return slice;
}

const std = @import("std");

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/09.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var total: i64 = 0;
    var i: i64 = 0;
    while (lines.next()) |line| : (i += 1) {
        const next_value = try solveLine(allocator, line);
        std.debug.print("Line {d} - {d}\n", .{ i, next_value });
        total += next_value;
    }
    std.debug.print("Total: {d}\n", .{total});
}

fn solveLine(allocator: std.mem.Allocator, line: []const u8) !i64 {
    var number_tokens = std.mem.tokenizeScalar(u8, line, ' ');
    var number_list = std.ArrayList(i64).init(allocator);

    while (number_tokens.next()) |number_token| {
        const number = try std.fmt.parseInt(i64, number_token, 10);
        try number_list.append(number);
    }

    const numbers = try number_list.toOwnedSlice();
    const next_number = getNextNumber(allocator, numbers);
    return next_number;
}

fn getNextNumber(allocator: std.mem.Allocator, numbers: []const i64) !i64 {
    var next_line = try allocator.alloc(i64, numbers.len - 1);
    defer allocator.free(next_line);

    for (0..numbers.len) |i| {
        if (i == 0) continue;
        const previous_number = numbers[i - 1];
        next_line[i - 1] = numbers[i] - previous_number;
    }

    var solved: bool = true;
    for (next_line) |number| {
        if (number != 0) solved = false;
    }

    if (solved) {
        return numbers[numbers.len - 1];
    }

    return numbers[numbers.len - 1] + try getNextNumber(allocator, next_line);
}

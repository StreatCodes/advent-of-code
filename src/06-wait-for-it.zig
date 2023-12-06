const std = @import("std");

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/06.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    const record_time = try extractNumber(allocator, lines.next().?);
    const record_distance = try extractNumber(allocator, lines.next().?);

    const wins = calculateWins(record_time, record_distance);

    std.debug.print("Total: {}\n", .{wins});
}

fn calculateWins(record_time: u64, record_distance: u64) u64 {
    var wins: u64 = 0;
    for (0..record_time) |time| {
        const remainder = record_time - time;
        const distance = remainder * time;
        if (distance > record_distance) {
            wins += 1;
        }
    }
    return wins;
}

fn extractNumber(allocator: std.mem.Allocator, line: []const u8) !u64 {
    var number_tokens = std.mem.tokenizeScalar(u8, line, ' ');
    _ = number_tokens.next(); //Discard text

    const number_text = try std.mem.replaceOwned(u8, allocator, number_tokens.rest(), " ", "");
    defer allocator.free(number_text);

    std.debug.print("Remaining {s}\n", .{number_text});
    const number = try std.fmt.parseInt(u64, number_text, 10);
    return number;
}

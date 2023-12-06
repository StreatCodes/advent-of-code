const std = @import("std");

const Game = struct {
    id: u32,
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/06.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    const record_times = try extractNumbers(allocator, lines.next().?);
    const record_distances = try extractNumbers(allocator, lines.next().?);

    var total: u32 = 0;
    var i: u32 = 0;
    while (i < record_times.len) : (i += 1) {
        const distances = try calculateDistances(allocator, record_times[i]);
        std.debug.print("Time: {}, Distance: {}\n", .{ record_times[i], distances[i] });

        var race_wins: u32 = 0;
        for (distances) |distance| {
            if (distance > record_distances[i]) {
                race_wins += 1;
            }
        }

        if (total == 0) {
            total = race_wins;
        } else {
            total *= race_wins;
        }
    }

    std.debug.print("Total: {}\n", .{total});
}

fn calculateDistances(allocator: std.mem.Allocator, max_time: u32) ![]u32 {
    const distances = try allocator.alloc(u32, max_time);
    for (0..max_time) |time| {
        const remainder = max_time - time;
        const distance = remainder * time;
        distances[time] = @intCast(distance);
    }
    return distances;
}

fn extractNumbers(allocator: std.mem.Allocator, line: []const u8) ![]u32 {
    var number_tokens = std.mem.tokenizeScalar(u8, line, ' ');
    _ = number_tokens.next(); //Discard text

    var numbers = std.ArrayList(u32).init(allocator);
    while (number_tokens.next()) |token| {
        const number = try std.fmt.parseInt(u32, token, 10);
        try numbers.append(number);
    }
    return try numbers.toOwnedSlice();
}

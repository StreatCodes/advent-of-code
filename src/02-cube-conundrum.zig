const std = @import("std");

const Game = struct {
    id: u32,
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/02.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var game_sum: u32 = 0;
    var i: u32 = 1;
    while (lines.next()) |line| : (i += 1) {
        const skip = try std.fmt.allocPrint(allocator, "Game {d}: ", .{i});

        const game = line[skip.len..];

        var sets = std.mem.tokenizeSequence(u8, game, "; ");

        var game_result: Game = .{ .id = i };
        while (sets.next()) |set| {
            const set_result = try extract_set(i, set);
            if (set_result.red > game_result.red) game_result.red = set_result.red;
            if (set_result.green > game_result.green) game_result.green = set_result.green;
            if (set_result.blue > game_result.blue) game_result.blue = set_result.blue;
        }
        std.debug.print("Game {d}: R {} G {} B {}\n", .{ game_result.id, game_result.red, game_result.green, game_result.blue });

        const power = game_result.red * game_result.green * game_result.blue;

        game_sum += power;
    }

    std.debug.print("Game sum: {d}\n", .{game_sum});
}

fn extract_set(game_id: u32, set: []const u8) !Game {
    var game = Game{
        .id = game_id,
    };

    var colors = std.mem.tokenizeSequence(u8, set, ", ");
    while (colors.next()) |color| {
        if (std.mem.endsWith(u8, color, "red")) game.red = try get_number(color);
        if (std.mem.endsWith(u8, color, "green")) game.green = try get_number(color);
        if (std.mem.endsWith(u8, color, "blue")) game.blue = try get_number(color);
    }

    return game;
}

fn get_number(color: []const u8) !u32 {
    var parts = std.mem.tokenize(u8, color, " ");
    return try std.fmt.parseInt(u32, parts.next() orelse "0", 10);
}

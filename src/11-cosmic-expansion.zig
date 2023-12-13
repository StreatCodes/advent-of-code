const std = @import("std");

const Position = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/11.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var universe = std.ArrayList([]const u8).init(allocator);
    // defer universe.deinit();
    while (lines.next()) |line| {
        try universe.append(line);
    }

    var galaxy_positions = std.ArrayList(Position).init(allocator);

    for (universe.items, 0..) |row, y| {
        for (row, 0..) |c, x| {
            if (c == '#') {
                try galaxy_positions.append(Position{ .x = x, .y = y });
            }
        }
    }

    var total_distance: u64 = 0;
    for (galaxy_positions.items) |pos| {
        for (galaxy_positions.items, 0..) |other_pos, i| {
            _ = i;

            if (pos.x == other_pos.x and pos.y == other_pos.y) continue;
            const distance = getDistance(universe, pos, other_pos);
            total_distance += distance;
        }
    }
    //Every galaxy is check against one another twice due to the loop above, so just divide by 2
    std.debug.print("total distance: {d}\n", .{total_distance / 2});
}

fn getDistance(universe: std.ArrayList([]const u8), pos: Position, other_pos: Position) u64 {
    const posx: u64 = @min(pos.x, other_pos.x);
    const posy: u64 = @min(pos.y, other_pos.y);
    var other_posx: u64 = @max(pos.x, other_pos.x);
    var other_posy: u64 = @max(pos.y, other_pos.y);

    for (posx..other_posx) |x| {
        if (isExpandedColumn(universe, x)) other_posx += 999_999;
    }

    for (posy..other_posy) |y| {
        if (isExpandedRow(universe, y)) other_posy += 999_999;
    }

    return @intCast((other_posx - posx) + (other_posy - posy));
}

fn isExpandedRow(universe: std.ArrayList([]const u8), row_index: usize) bool {
    const row = universe.items[row_index];
    for (row) |c| {
        if (c != '.') return false;
    }
    return true;
}

fn isExpandedColumn(universe: std.ArrayList([]const u8), col_index: usize) bool {
    for (universe.items) |row| {
        if (row[col_index] != '.') return false;
    }
    return true;
}

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

    std.debug.print("universe len: {d}x{d}\n", .{ universe.items.len, universe.items[0].len });
    try expandUniverse(allocator, &universe);
    std.debug.print("resized universe len: {d}x{d}\n", .{ universe.items.len, universe.items[0].len });

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
            const posx: i64 = @intCast(pos.x);
            const posy: i64 = @intCast(pos.y);
            const other_posx: i64 = @intCast(other_pos.x);
            const other_posy: i64 = @intCast(other_pos.y);

            const distance: u64 = @abs(posx - other_posx) + @abs(posy - other_posy);
            std.debug.print("distance {d}\n", .{distance});
            total_distance += distance;
        }
    }
    //Every galaxy is check against one another twice due to the loop above, so just divide by 2
    std.debug.print("total distance: {d}\n", .{total_distance / 2});
}

fn expandUniverse(allocator: std.mem.Allocator, universe: *std.ArrayList([]const u8)) !void {
    var i: usize = 0;
    var row_count = universe.items.len;
    outer: while (i < row_count) : (i += 1) {
        const line = universe.items[i];
        for (line) |c| {
            if (c != '.') continue :outer;
        }
        const new_line = try allocator.alloc(u8, line.len);
        @memset(new_line, '.');
        row_count += 1;
        // try universe.resize(row_count);
        try universe.insert(i, new_line);
        i += 1;
    }

    // allocator.realloc(old_mem: anytype, new_n: usize);
    var expand_cols = std.ArrayList(usize).init(allocator);
    defer expand_cols.deinit();
    outer: for (0..universe.items[0].len) |col| {
        for (0..universe.items.len) |j| {
            const c = universe.items[j][col];
            if (c != '.') continue :outer;
        }
        try expand_cols.append(col);
    }

    i = 0;
    while (i < universe.items.len) : (i += 1) {
        universe.items[i] = try shiftRow(allocator, universe.items[i], expand_cols.items);
    }
}

fn shiftRow(allocator: std.mem.Allocator, row: []const u8, shift_positions: []usize) ![]const u8 {
    var new_row = try allocator.alloc(u8, row.len + shift_positions.len);
    var i: usize = 0;
    var shift_id: usize = 0;
    while (i < new_row.len) : (i += 1) {
        if (shift_id < shift_positions.len and shift_positions[shift_id] + shift_id == i) {
            new_row[i] = '.';
            shift_id += 1;
        } else {
            new_row[i] = row[i - shift_id];
        }
    }
    return new_row;
}

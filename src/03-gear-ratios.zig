const std = @import("std");

const Gear = struct {
    touching: bool,
    col: u32 = 0,
    row: u32 = 0,
    value: u32 = 0,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/03.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    defer allocator.free(input_string);
    var line_iter = std.mem.tokenizeScalar(u8, input_string, '\n');

    var line_array = std.ArrayList([]const u8).init(allocator);
    defer line_array.deinit();
    while (line_iter.next()) |line| {
        try line_array.append(line);
    }

    const lines = try line_array.toOwnedSlice();

    var total: u32 = 0;
    var i: u32 = 0;
    var all_gears = std.ArrayList(Gear).init(allocator);
    defer all_gears.deinit();
    //Find any values considered a gear
    while (i < lines.len) : (i += 1) {
        //This is leaking memory as we don't ever free these
        const gears = try extract_gears(allocator, lines, i);
        try all_gears.appendSlice(gears);
    }

    i = 0;
    var gears_done = std.ArrayList(Gear).init(allocator);
    //Iterate all the found gears
    outer: while (i < all_gears.items.len) : (i += 1) {
        const gear = all_gears.items[i];
        var j: u32 = 0;
        var second_gear: ?Gear = null;
        //Filter out any gears with exactly two matches
        while (j < all_gears.items.len) : (j += 1) {
            if (j == i) continue;
            if (all_gears.items[j].col == gear.col and all_gears.items[j].row == gear.row) {
                if (second_gear == null) {
                    second_gear = all_gears.items[j];
                } else {
                    continue :outer;
                }
            }
        }

        //Make sure we haven't already done this gear, if so then calculate the ratio and increase the total
        if (second_gear != null) {
            var included = false;
            for (gears_done.items) |g| {
                if (g.col == gear.col and g.row == gear.row) included = true;
            }

            if (!included) {
                try gears_done.append(gear);
                std.debug.print("Gear ratio {d} {d}\n", .{ gear.value, second_gear.?.value });
                total += gear.value * second_gear.?.value;
            }
        }
    }
    std.debug.print("Total: {d}\n", .{total});
}

fn extract_gears(allocator: std.mem.Allocator, lines: [][]const u8, row: u32) ![]Gear {
    var gears = std.ArrayList(Gear).init(allocator);
    defer gears.deinit();
    const line = lines[row];
    var i: u32 = 0;
    while (i < line.len) : (i += 1) {
        if (is_number(line[i])) {
            var j = i;
            var touching_gear: ?Gear = undefined;
            while (j < line.len and is_number(line[j])) {
                const gear = is_touching_gear(lines, row, j);
                if (gear.touching) touching_gear = gear;
                j += 1;
            }
            if (touching_gear != null) {
                const number = try std.fmt.parseInt(u32, line[i..j], 10);
                touching_gear.?.value = number;
                try gears.append(touching_gear.?);
            }
            i = j;
        }
    }
    return try gears.toOwnedSlice();
}

fn is_number(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn is_gear(c: u8) bool {
    if (c == '*') return true;
    return false;
}

fn is_touching_gear(lines: [][]const u8, row: u32, col: u32) Gear {
    //Check previous row
    if (row > 0) {
        const prev_line = lines[row - 1];
        if (col > 0 and is_gear(prev_line[col - 1])) return Gear{ .touching = true, .col = col - 1, .row = row - 1 };
        if (is_gear(prev_line[col])) return Gear{ .touching = true, .col = col, .row = row - 1 };
        if (col + 1 < prev_line.len and is_gear(prev_line[col + 1])) return Gear{ .touching = true, .col = col + 1, .row = row - 1 };
    }

    //Check next row
    if (row + 1 < lines.len) {
        const next_line = lines[row + 1];
        if (col > 0 and is_gear(next_line[col - 1])) return Gear{ .touching = true, .col = col - 1, .row = row + 1 };
        if (is_gear(next_line[col])) return Gear{ .touching = true, .col = col, .row = row + 1 };
        if (col + 1 < next_line.len and is_gear(next_line[col + 1])) return Gear{ .touching = true, .col = col + 1, .row = row + 1 };
    }

    //Check left and right on current row
    const line = lines[row];
    if (col > 0 and is_gear(line[col - 1])) return Gear{ .touching = true, .col = col - 1, .row = row };
    if (col + 1 < line.len and is_gear(line[col + 1])) return Gear{ .touching = true, .col = col + 1, .row = row };

    return Gear{ .touching = false };
}

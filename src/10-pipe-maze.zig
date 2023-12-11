const std = @import("std");

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Pipe = struct {
    a: Direction,
    b: Direction,
};

const TileType = enum {
    start,
    pipe,
    ground,
};

const Tile = struct {
    glyph: u8,
    type: TileType,
    pipe: ?Pipe,
};

const Position = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/10.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    defer allocator.free(input_string);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var tile_rows = std.ArrayList([]Tile).init(allocator);

    while (lines.next()) |line| {
        var tile_columns = try allocator.alloc(Tile, line.len);
        for (line, 0..) |c, i| {
            tile_columns[i] = tokenToTile(c);
        }

        try tile_rows.append(tile_columns);
    }

    const start = findStart(tile_rows.items);
    //TODO remove this hard coded value and find it with a function
    const length = findPathLength(tile_rows.items, start, Direction.right);
    const middle_point = (length / 2) + (length % 2);
    std.debug.print("Length: {d} - Middle: {d}\n", .{ length, middle_point });
}

fn tokenToTile(token: u8) Tile {
    switch (token) {
        '.' => return .{ .glyph = '.', .type = TileType.ground, .pipe = null },
        'S' => return .{ .glyph = 'S', .type = TileType.start, .pipe = null },
        '-' => return .{ .glyph = '-', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.left, .b = Direction.right } },
        '|' => return .{ .glyph = '|', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.up, .b = Direction.down } },
        'L' => return .{ .glyph = 'L', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.up, .b = Direction.right } },
        'J' => return .{ .glyph = 'J', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.up, .b = Direction.left } },
        '7' => return .{ .glyph = '7', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.left, .b = Direction.down } },
        'F' => return .{ .glyph = 'F', .type = TileType.pipe, .pipe = Pipe{ .a = Direction.right, .b = Direction.down } },
        else => {
            std.debug.print("Unknown token: {c}\n", .{token});
            unreachable;
        },
    }
}

fn findStart(tile_rows: [][]Tile) Position {
    for (tile_rows, 0..) |row, y| {
        for (row, 0..) |tile, x| {
            if (tile.type == TileType.start) {
                return Position{ .x = x, .y = y };
            }
        }
    }

    unreachable;
}

fn matchingDirection(direction: Direction) Direction {
    switch (direction) {
        Direction.up => return Direction.down,
        Direction.down => return Direction.up,
        Direction.left => return Direction.right,
        Direction.right => return Direction.left,
    }
}

fn findPathLength(tile_rows: [][]Tile, start: Position, start_direction: Direction) u32 {
    var current = start;
    var direction = start_direction;
    var count: u32 = 0;
    while (true) {
        switch (direction) {
            Direction.up => current.y -= 1,
            Direction.right => current.x += 1,
            Direction.down => current.y += 1,
            Direction.left => current.x -= 1,
        }

        if (current.x < 0 or current.y < 0 or current.x >= tile_rows[0].len or current.y >= tile_rows.len) {
            std.debug.print("Out of bounds\n", .{});
            unreachable;
        }

        const tile = tile_rows[current.y][current.x];
        if (tile.type == TileType.start) break;
        count += 1;

        if (tile.pipe.?.a == matchingDirection(direction)) {
            direction = tile.pipe.?.b;
        } else if (tile.pipe.?.b == matchingDirection(direction)) {
            direction = tile.pipe.?.a;
        } else {
            std.debug.print("Input direction not found.\n", .{});
            unreachable;
        }

        std.debug.print("Moved to {c} ({d},{d})\n", .{ tile.glyph, current.x, current.y });
    }

    return count;
}

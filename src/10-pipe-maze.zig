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

    fn pipeExit(self: Pipe, entry: Direction) Direction {
        const entry_port = matchingDirection(entry);
        if (self.a == entry_port) return self.b;
        if (self.b == entry_port) return self.a;
        unreachable;
    }
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
    direction: ?Direction = null, //Direction entered
};

//This ended up being a hack to just fill the inside of the loop with I's.
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
    const start_direction = findStartDirection(tile_rows.items, start);
    const main_path = try mapPath(allocator, tile_rows.items, start, start_direction);

    for (tile_rows.items, 0..) |row, y| {
        for (row, 0..) |*tile, x| {
            if (!inPositions(main_path, .{ .x = x, .y = y })) {
                tile.glyph = '.';
                tile.type = TileType.ground;
            }
        }
    }

    // var inside_positions = std.ArrayList(Position).init(allocator);
    for (main_path) |p| {
        // tile_rows.items[p.y][p.x].glyph = 'O';
        const check_spots = try insidePositions(allocator, tile_rows.items, p);
        defer allocator.free(check_spots);
        for (check_spots) |check_spot| {
            if (check_spot.x < 0 or check_spot.y < 0 or check_spot.x >= tile_rows.items[0].len or check_spot.y >= tile_rows.items.len) continue;

            const tile = &tile_rows.items[check_spot.y][check_spot.x];
            if (tile.type == TileType.ground) {
                tile.*.glyph = 'I';
                std.debug.print("Found inside position at ({d},{d})\n", .{ check_spot.x, check_spot.y });
            }
        }
    }

    for (tile_rows.items, 0..) |row, y| {
        for (row, 0..) |*tile, x| {
            if (tile.glyph == '.' and touchingInside(tile_rows.items, .{ .x = x, .y = y })) {
                tile.glyph = 'I';
            }
        }
    }

    var count: u32 = 0;
    var out_file = try std.fs.cwd().createFile("out.txt", .{ .truncate = true });
    defer out_file.close();
    var writer = out_file.writer();
    for (tile_rows.items) |row| {
        for (row) |tile| {
            if (tile.glyph == 'I') count += 1;
            try writer.writeByte(tile.glyph);
        }
        try writer.writeByte('\n');
    }

    std.debug.print("Inside tiles: {d}\n", .{count});
}

fn touchingInside(tile_rows: [][]Tile, position: Position) bool {
    if (position.x > 0) {
        const tile = tile_rows[position.y][position.x - 1];
        if (tile.glyph == 'I') return true;
    }
    if (position.x + 1 < tile_rows[0].len) {
        const tile = tile_rows[position.y][position.x + 1];
        if (tile.glyph == 'I') return true;
    }
    if (position.y > 0) {
        const tile = tile_rows[position.y - 1][position.x];
        if (tile.glyph == 'I') return true;
    }
    if (position.y + 1 < tile_rows.len) {
        const tile = tile_rows[position.y + 1][position.x];
        if (tile.glyph == 'I') return true;
    }

    return false;
}

//This gets all the positions on the inside of the main loop.
//It assumes we're iterating the main loop in a clockwise direction.
fn insidePositions(allocator: std.mem.Allocator, tile_rows: [][]Tile, position: Position) ![]Position {
    const tile = tile_rows[position.y][position.x];
    const pipe_exit = tile.pipe.?.pipeExit(position.direction.?);
    var positions = std.ArrayList(Position).init(allocator);

    switch (position.direction.?) {
        Direction.up => {
            switch (pipe_exit) {
                Direction.up => {
                    try positions.append(.{ .x = position.x + 1, .y = position.y });
                },
                Direction.left => {
                    if (@as(i32, @intCast(position.y)) - 1 > 0) {
                        try positions.append(.{ .x = position.x, .y = position.y - 1 });
                    }
                    try positions.append(.{ .x = position.x + 1, .y = position.y });
                },
                else => {},
            }
        },
        Direction.down => {
            switch (pipe_exit) {
                Direction.down => {
                    if (@as(i32, @intCast(position.x)) - 1 > 0) {
                        try positions.append(.{ .x = position.x - 1, .y = position.y });
                    }
                },
                Direction.right => {
                    try positions.append(.{ .x = position.x, .y = position.y + 1 });
                    try positions.append(.{ .x = position.x - 1, .y = position.y });
                },
                else => {},
            }
        },
        Direction.left => {
            switch (pipe_exit) {
                Direction.left => {
                    if (@as(i32, @intCast(position.y)) - 1 > 0) {
                        try positions.append(.{ .x = position.x, .y = position.y - 1 });
                    }
                },
                Direction.down => {
                    if (@as(i32, @intCast(position.x)) - 1 > 0) {
                        try positions.append(.{ .x = position.x - 1, .y = position.y });
                    }
                    if (@as(i32, @intCast(position.y)) - 1 > 0) {
                        try positions.append(.{ .x = position.x, .y = position.y - 1 });
                    }
                },
                else => {},
            }
        },
        Direction.right => {
            switch (pipe_exit) {
                Direction.right => {
                    try positions.append(.{ .x = position.x, .y = position.y + 1 });
                },
                Direction.up => {
                    try positions.append(.{ .x = position.x, .y = position.y + 1 });
                    try positions.append(.{ .x = position.x + 1, .y = position.y });
                },
                else => {},
            }
        },
    }

    return try positions.toOwnedSlice();
}

fn inPositions(path: []Position, position: Position) bool {
    for (path) |p| {
        if (p.x == position.x and p.y == position.y) return true;
    }

    return false;
}

fn findStartDirection(tile_rows: [][]Tile, start: Position) Direction {
    if (start.y > 0) {
        const tile = tile_rows[start.y - 1][start.x];
        if (hasDirection(tile, Direction.down)) return Direction.up;
    }
    if (start.y + 1 < tile_rows.len) {
        const tile = tile_rows[start.y + 1][start.x];
        if (hasDirection(tile, Direction.up)) return Direction.down;
    }
    if (start.x > 0) {
        const tile = tile_rows[start.y][start.x - 1];
        if (hasDirection(tile, Direction.right)) return Direction.left;
    }
    if (start.x + 1 < tile_rows[0].len) {
        const tile = tile_rows[start.y][start.x + 1];
        if (hasDirection(tile, Direction.left)) return Direction.right;
    }

    unreachable;
}

fn hasDirection(tile: Tile, direction: Direction) bool {
    if (tile.pipe.?.a == direction) return true;
    if (tile.pipe.?.b == direction) return true;
    return false;
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

fn mapPath(allocator: std.mem.Allocator, tile_rows: [][]Tile, start: Position, start_direction: Direction) ![]Position {
    var current = start;
    var direction = start_direction;
    var path = std.ArrayList(Position).init(allocator);
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
        current.direction = direction;
        try path.append(current);

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

    return path.toOwnedSlice();
}

const std = @import("std");

const Path = struct {
    left: []const u8,
    right: []const u8,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/08.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    const directions = lines.next().?;
    // _ = lines.next().?; //Discard empty line

    var atlas = std.StringHashMap(Path).init(allocator);
    defer atlas.deinit();
    while (lines.next()) |line| {
        var line_values = std.mem.splitSequence(u8, line, " = ");
        const id = line_values.next().?;
        const path_values = line_values.next().?;
        const path = Path{
            .left = path_values[1..4],
            .right = path_values[6..9],
        };

        try atlas.put(id, path);
        std.debug.print("Paths: {s} - {s} {s}\n", .{ id, path.left, path.right });
    }

    var location_list = std.ArrayList([]const u8).init(allocator);
    defer location_list.deinit();
    var iter = atlas.iterator();
    while (iter.next()) |v| {
        if (v.key_ptr.*[2] == 'A') {
            std.debug.print("Starting: {s}\n", .{v.key_ptr.*});
            try location_list.append(v.key_ptr.*);
        }
    }

    const locations = try location_list.toOwnedSlice();
    defer allocator.free(locations);

    var offset: u64 = 0;
    var total: u64 = 0;
    outer: while (true) {
        if (total % 10_000_000 == 0) {
            std.debug.print("total: {d}\n", .{total});
        }
        const direction = directions[offset];
        for (locations) |*location| {
            const map = atlas.get(location.*).?;

            if (direction == 'L') {
                location.* = map.left;
            } else {
                location.* = map.right;
            }
        }

        offset += 1;
        if (offset == directions.len) offset = 0;
        total += 1;

        var count: u32 = 0;
        for (locations) |location| {
            if (location[2] == 'Z') {
                count += 1;
            }

            if (count == locations.len) {
                break :outer;
            }
        }
    }
    std.debug.print("Total: {}\n", .{total});
}

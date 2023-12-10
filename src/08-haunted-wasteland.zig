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

    //Create map of paths
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
    }

    var atlas_iter = atlas.iterator();

    //Solve each path ending with A
    var distances_list = std.ArrayList(u64).init(allocator);
    while (atlas_iter.next()) |entry| {
        if (entry.key_ptr.*[2] == 'A') {
            const distance = calcNextLocation(
                atlas,
                entry.key_ptr.*,
                directions,
            );
            try distances_list.append(distance);
        }
    }

    const distances = try distances_list.toOwnedSlice();
    defer allocator.free(distances);
    var total_distances = try allocator.alloc(u64, distances.len);
    defer allocator.free(total_distances);
    @memset(total_distances, 0);

    var count: u64 = 0;

    //Find the lowest common denominator of all distances
    while (true) {
        var lowest: u64 = 0;
        count += 1;

        for (0..total_distances.len) |i| {
            if (i == 0) {
                lowest = total_distances[i];
            } else if (total_distances[i] < lowest) {
                lowest = total_distances[i];
            }
        }
        if (count % 100_000_000 == 0) {
            std.debug.print("lowest: {d}\n", .{lowest});
        }

        var low_count: u32 = 0;
        for (0..distances.len) |i| {
            if (lowest != 0 and total_distances[i] == lowest) {
                low_count += 1;
            }
        }

        if (low_count == distances.len) {
            break;
        }

        for (0..total_distances.len) |i| {
            if (total_distances[i] == lowest) {
                total_distances[i] += distances[i];
            }
        }
    }

    std.debug.print("Total: {d}\n", .{total_distances[0]});
}

fn calcNextLocation(atlas: std.StringHashMap(Path), current_position: []const u8, directions: []const u8) u64 {
    var position = current_position;
    var current_direction: u32 = 0;
    var distance: u64 = 0;

    while (true) {
        const map = atlas.get(position).?;

        if (directions[current_direction] == 'L') {
            position = map.left;
        } else {
            position = map.right;
        }
        distance += 1;

        current_direction += 1;
        if (current_direction == directions.len) current_direction = 0;

        if (position[2] == 'Z') {
            std.debug.print("pos: {s} - {d}\n", .{ position, distance });
            break;
        }

        if (std.mem.eql(u8, "XXX", position)) break;
    }
    return distance;
}

const std = @import("std");

const SourceMap = struct {
    source: u64,
    destination: u64,
    range: u64,
};

const SeedRange = struct {
    start: u64,
    range: u64,
};

fn sortSourceMap(_: void, a: SourceMap, b: SourceMap) bool {
    return a.source < b.source;
}

//For some reason this program only returns the correct result when running a debug build.
pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/05.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var line_iter = std.mem.splitScalar(u8, input_string, '\n');

    const seed_line = line_iter.next();
    const seed_ranges = try extractNumbers(allocator, seed_line.?[7..]);
    std.debug.print("Seeds: {any}\n", .{seed_ranges});

    _ = line_iter.next(); //Skip this empty line

    var almanac = std.ArrayList([]SourceMap).init(allocator);
    var map_list = std.ArrayList(SourceMap).init(allocator);

    while (line_iter.next()) |line| {
        if (line.len == 0) {
            std.debug.print("Creating new map list and appending to almanac\n", .{});
            const map_list_slice = try map_list.toOwnedSlice();
            std.mem.sort(SourceMap, map_list_slice, {}, sortSourceMap);
            try almanac.append(map_list_slice);
            map_list.deinit();
            map_list = std.ArrayList(SourceMap).init(allocator);
            continue;
        }
        if (line[0] >= 'a' and line[0] <= 'z') {
            continue;
        }

        const map = try parseMapLine(allocator, line);
        try map_list.append(map);
    }

    var lowestLocation: u64 = undefined;
    var i: u64 = 0;
    while (i < seed_ranges.len) : (i += 2) {
        const seed_start = seed_ranges[i];
        const seed_range = seed_ranges[i + 1];
        std.debug.print("Running range: {d} - {d}\n", .{ seed_start, seed_start + seed_range });

        var seed: u64 = seed_start;
        while (seed < seed_start + seed_range) : (seed += 1) {
            // if ((seed % 10000000) == 0) {
            //     std.debug.print("Iters: {d}\n", .{seed});
            // }
            const location = try evalSeedLocation(seed, almanac.items);
            if (lowestLocation == undefined or location < lowestLocation) {
                lowestLocation = location;
            }
        }
    }

    std.debug.print("Lowest Location: {d}\n", .{lowestLocation});
}

fn evalSeedLocation(seed: u64, almanac: [][]SourceMap) !u64 {
    var result: u64 = seed;
    for (almanac) |maps| {
        result = evalMaps(result, maps);
    }
    return result;
}

fn evalMaps(seed: u64, maps: []SourceMap) u64 {
    var result: ?u64 = null;
    for (maps) |map| {
        if (seed < map.source) {
            result = seed;
            // std.debug.print("Unchanged {d} -> {d}\n", .{ result.?, result.? });
            break;
        }
        if (seed < map.source + map.range) {
            result = map.destination + (seed - map.source);
            // std.debug.print("Mapped {d} -> {d}\n", .{ seed, result.? });
            break;
        }
    }
    if (result == null) {
        result = seed;
        // std.debug.print("Unchanged {d} -> {d}\n", .{ result.?, result.? });
    }

    return result.?;
}

fn parseMapLine(allocator: std.mem.Allocator, line: []const u8) !SourceMap {
    const numbers = try extractNumbers(allocator, line);
    return SourceMap{
        .destination = numbers[0],
        .source = numbers[1],
        .range = numbers[2],
    };
}

fn extractNumbers(allocator: std.mem.Allocator, line: []const u8) ![]u64 {
    var results = std.ArrayList(u64).init(allocator);
    var iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (iter.next()) |token| {
        const number = try std.fmt.parseInt(u64, token, 10);
        try results.append(number);
    }
    return results.toOwnedSlice();
}

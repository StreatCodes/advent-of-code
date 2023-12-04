const std = @import("std");

const Cache = struct {
    winning: []u32,
    our: []u32,
};

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/04.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var line_iter = std.mem.tokenizeScalar(u8, input_string, '\n');

    var line_array = std.ArrayList([]const u8).init(allocator);
    defer line_array.deinit();
    while (line_iter.next()) |line| {
        try line_array.append(line);
    }

    const lines = try line_array.toOwnedSlice();

    //Hard coded input line length, easier
    var duplicates = try allocator.alloc(u32, 198);
    defer allocator.free(duplicates);
    for (duplicates) |*dupe| {
        dupe.* = 0;
    }

    const cache = try allocator.alloc(?Cache, 198);
    defer allocator.free(cache);
    for (cache) |*cached| {
        cached.* = null;
    }

    //Ok i'll optimise this loop with a cache of the extract functions.
    //I'm sure there is some math that can be done to take the results of each iteration
    //without having to recalculate the duplicates and totals each time.
    //though for once writing it in zig is an advantage with `zig build run-scratchcards -Doptimize=ReleaseFast`
    //this program is littered with memory leaks though..
    var total: u32 = 0;
    var i: u32 = 0;
    while (i < lines.len) {
        const line = lines[i];

        var winning_numbers: []u32 = undefined;
        var our_numbers: []u32 = undefined;
        if (cache[i] == null) {
            winning_numbers = try extract_winning_numbers(allocator, line);
            our_numbers = try extract_our_numbers(allocator, line);

            cache[i] = Cache{ .winning = winning_numbers, .our = our_numbers };
        } else {
            winning_numbers = cache[i].?.winning;
            our_numbers = cache[i].?.our;
        }

        var dupes: u32 = 0;
        for (our_numbers) |our_number| {
            for (winning_numbers) |winning_number| {
                if (our_number == winning_number) dupes += 1;
            }
        }

        while (dupes > 0) : (dupes -= 1) {
            if (i + dupes > duplicates.len) continue;
            duplicates[i + dupes] += 1;
        }

        total += 1;

        if (total % 10000 == 0) std.debug.print("total: {d}\n", .{total});

        if (duplicates[i] > 0) {
            duplicates[i] -= 1;
        } else {
            i += 1;
            std.debug.print("incrementing {d}\n", .{i});
        }
    }

    std.debug.print("Total: {d}\n", .{total});
}

fn extract_winning_numbers(allocator: std.mem.Allocator, line: []const u8) ![]u32 {
    const trim_point = std.mem.indexOfScalar(u8, line, ':');
    if (trim_point == null) unreachable;

    const new_line = line[trim_point.? + 2 ..];

    var result_match = std.mem.tokenizeSequence(u8, new_line, " | ");
    const result_line = result_match.next();
    if (result_line == null) unreachable;

    var result_values = std.mem.tokenizeAny(u8, result_line.?, " ");
    var result_numbers = std.ArrayList(u32).init(allocator);

    while (result_values.next()) |result_value| {
        const number = try std.fmt.parseInt(u32, result_value, 10);
        try result_numbers.append(number);
    }

    return result_numbers.toOwnedSlice();
}

fn extract_our_numbers(allocator: std.mem.Allocator, line: []const u8) ![]u32 {
    const trim_point = std.mem.indexOfScalar(u8, line, ':');
    if (trim_point == null) unreachable;

    const new_line = line[trim_point.? + 2 ..];

    var our_match = std.mem.tokenizeSequence(u8, new_line, " | ");
    _ = our_match.next();
    const our_line = our_match.next();
    if (our_line == null) unreachable;

    var our_values = std.mem.tokenizeAny(u8, our_line.?, " ");
    var our_numbers = std.ArrayList(u32).init(allocator);

    while (our_values.next()) |our_value| {
        const number = try std.fmt.parseInt(u32, our_value, 10);
        try our_numbers.append(number);
    }

    return our_numbers.toOwnedSlice();
}

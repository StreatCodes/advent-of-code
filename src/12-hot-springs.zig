const std = @import("std");

// # - damaged
// . - working
// ? - unknown

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/12-example.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    defer allocator.free(input_string);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var total: u64 = 0;
    while (lines.next()) |line| {
        var split_line = std.mem.splitScalar(u8, line, ' ');
        const partial_springs = split_line.next().?;

        var springs = std.ArrayList(u8).init(allocator);
        try springs.appendSlice(partial_springs);
        for (0..4) |_| {
            try springs.append('?');
            try springs.appendSlice(partial_springs);
        }

        std.debug.print("Springs: {s}\n", .{springs.items});
        const instruction_line = split_line.next().?;
        const instructions = try extractInstructions(allocator, instruction_line);

        const variations = try calculateVariations(allocator, springs.items, instructions);
        total += variations;

        std.debug.print("vartions: {d}\n", .{variations});
        break;
    }
    std.debug.print("Total: {d}\n", .{total});
}

fn extractInstructions(allocator: std.mem.Allocator, instructions: []const u8) ![]u32 {
    var results = std.ArrayList(u32).init(allocator);
    var instruction_tokens = std.mem.splitScalar(u8, instructions, ',');

    while (instruction_tokens.next()) |token| {
        const number = try std.fmt.parseInt(u32, token, 10);
        try results.append(number);
    }
    const len = results.items.len;
    for (0..4) |_| {
        const duped = try allocator.alloc(u32, len);
        @memcpy(duped, results.items[0..len]);
        try results.appendSlice(duped);
    }

    return try results.toOwnedSlice();
}

fn nthBitSet(value: usize, n: usize) bool {
    return 1 == (value >> @intCast(n)) & 1;
}

//TODO this is wrong doesn't generate # with gaps in between
fn calculateVariations(allocator: std.mem.Allocator, springs: []const u8, instructions: []u32) !u32 {
    var variations = std.ArrayList([]const u8).init(allocator);
    var unknown_indexes = std.ArrayList(usize).init(allocator);
    defer unknown_indexes.deinit();

    for (springs, 0..) |spring, i| {
        if (spring == '?') {
            try unknown_indexes.append(i);
        }
    }

    const upper = std.math.pow(usize, 2, unknown_indexes.items.len);
    outer: for (0..upper) |i| {
        const variation = try allocator.alloc(u8, springs.len);
        @memcpy(variation, springs);

        for (unknown_indexes.items, 0..) |index, j| {
            const bit = nthBitSet(i, j);
            variation[index] = if (bit) '#' else '.';
        }

        for (variations.items) |other| {
            if (std.mem.eql(u8, variation, other)) {
                allocator.free(variation);
                continue :outer;
            }
        }

        try variations.append(variation);
    }

    std.debug.print("Possible spring patterns: {d}\n", .{variations.items.len});

    var total: u32 = 0;
    for (variations.items) |variation| {
        if (verifyVariation(variation, instructions)) {
            total += 1;
        }
    }

    return total;
}

fn verifyVariation(springs: []const u8, instructions: []u32) bool {
    var i: usize = 0;
    var matches: u32 = 0;

    while (i < springs.len) {
        const matcher = springs[i];
        const next_matcher: u8 = if (matcher == '#') '.' else '#';
        const next_match = std.mem.indexOfScalar(u8, springs[i..], next_matcher);

        const sequence = if (next_match != null) springs[i .. i + next_match.?] else springs[i..];
        const isMatch = sliceMatches(sequence, matcher, instructions[matches]);

        if (springs[i] != '.' and !isMatch) break; //Abort early

        if (isMatch) {
            matches += 1;

            if (matches == instructions.len) {
                if (next_match != null) { //Abort early
                    i = next_match.? + i;
                    while (i < springs.len) : (i += 1) {
                        if (springs[i] != '.') {
                            std.debug.print("NOT Matched: {s} - {any}\n", .{ springs, instructions });
                            return false;
                        }
                    }
                }

                std.debug.print("Matched: {s} - {any}\n", .{ springs, instructions });
                return true;
            }
        }

        if (next_match != null) {
            i = next_match.? + i;
        } else {
            break;
        }
    }

    return false;
}

fn sliceMatches(springs: []const u8, match: u8, count: u32) bool {
    const undamaged = std.mem.count(u8, springs, ".");
    _ = undamaged;
    const damaged = std.mem.count(u8, springs, "#");

    switch (match) {
        '.' => return false, //undamaged == count,
        '#' => return damaged == count,
        else => unreachable,
    }
}

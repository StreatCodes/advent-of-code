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
        const instruction_line = split_line.next().?;
        std.debug.print("Springs: {s} - {s}\n", .{ partial_springs, instruction_line });

        var starter_variation: u64 = 0;
        for (0..2) |dupes| {
            var springs = std.ArrayList(u8).init(allocator);
            defer springs.deinit();
            try springs.appendSlice(partial_springs);
            for (0..dupes) |_| {
                try springs.append('?');
                try springs.appendSlice(partial_springs);
            }

            const instructions = try extractInstructions(allocator, instruction_line, dupes);
            defer allocator.free(instructions);

            const variations = try calculateVariations(allocator, springs.items, instructions);

            if (dupes == 0) {
                starter_variation = variations;
                std.debug.print("Starter: {d}\n", .{starter_variation});
            } else {
                const multiplier = variations / starter_variation;
                var multiplied = variations;
                std.debug.print("Initial: {d}\n", .{multiplied});
                for (0..3) |_| {
                    multiplied *= multiplier;
                    std.debug.print("Multiplied: {d}\n", .{multiplied});
                }
                total += multiplied;
            }
        }

        // std.debug.print("vartions: {d}\n", .{variations});
    }
    std.debug.print("Total: {d}\n", .{total});
}

fn extractInstructions(allocator: std.mem.Allocator, instructions: []const u8, dupes: usize) ![]u32 {
    var results = std.ArrayList(u32).init(allocator);
    var instruction_tokens = std.mem.splitScalar(u8, instructions, ',');

    while (instruction_tokens.next()) |token| {
        const number = try std.fmt.parseInt(u32, token, 10);
        try results.append(number);
    }
    const len = results.items.len;
    for (0..dupes) |_| {
        const duped = try allocator.alloc(u32, len);
        @memcpy(duped, results.items[0..len]);
        try results.appendSlice(duped);
    }

    return try results.toOwnedSlice();
}

inline fn nthBitSet(value: usize, n: usize) bool {
    return 1 == (value >> @intCast(n)) & 1;
}

fn calculateVariations(allocator: std.mem.Allocator, springs: []const u8, instructions: []u32) !u64 {
    var unknown_indexes = std.ArrayList(usize).init(allocator);
    defer unknown_indexes.deinit();

    for (springs, 0..) |spring, i| {
        if (spring == '?') {
            try unknown_indexes.append(i);
        }
    }

    const upper = std.math.pow(usize, 2, unknown_indexes.items.len);
    var variation = try allocator.alloc(u8, springs.len);
    defer allocator.free(variation);
    @memcpy(variation, springs);
    std.debug.print("Generating {d} variations\n", .{upper});
    var total: u64 = 0;

    var total_damaged: u32 = 0;
    for (instructions) |instruction| {
        total_damaged += instruction;
    }

    var not_skipped: u64 = 0;
    const damage_start = std.mem.count(u8, springs, "#");
    for (0..upper) |i| {
        var damaged = damage_start;
        for (unknown_indexes.items, 0..) |index, j| {
            const bit = nthBitSet(i, j);
            variation[index] = if (bit) '#' else '.';
            if (bit) damaged += 1;
        }
        //optimize
        if (damaged != total_damaged) {
            continue;
        }
        not_skipped += 1;

        if (verifyVariation(variation, instructions)) {
            total += 1;
        }
    }
    std.debug.print("Verified: {d}\n", .{not_skipped});

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
                            // std.debug.print("NOT Matched: {s} - {any}\n", .{ springs, instructions });
                            return false;
                        }
                    }
                }

                // std.debug.print("Matched: {s} - {any}\n", .{ springs, instructions });
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
    const damaged = std.mem.count(u8, springs, "#");

    switch (match) {
        '.' => return false, //undamaged == count,
        '#' => return damaged == count,
        else => unreachable,
    }
}

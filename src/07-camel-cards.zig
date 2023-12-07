const std = @import("std");

const HandType = enum(u32) {
    HighCard,
    OnePair,
    TwoPairs,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
};

const Player = struct {
    hand: []const u8,
    bid: []const u8,
};

fn sortHands(_: void, a: Player, b: Player) bool {
    const hand_a = calculateHand(a.hand);
    const hand_b = calculateHand(b.hand);
    if (hand_a != hand_b) {
        return @intFromEnum(hand_a) < @intFromEnum(hand_b);
    }

    return calculateHigherValue(a.hand, b.hand);
}

pub fn main() !void {
    std.debug.print("Reading file\n", .{});
    const file = try std.fs.cwd().openFile("inputs/07.txt", .{ .mode = .read_only });
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input_string = try file.readToEndAlloc(allocator, 1024 * 1000);
    var lines = std.mem.tokenizeAny(u8, input_string, "\n");

    var hands = std.ArrayList(Player).init(allocator);
    defer hands.deinit();

    while (lines.next()) |line| {
        var hand = Player{ .bid = undefined, .hand = undefined };
        var data = std.mem.tokenizeAny(u8, line, " ");
        hand.hand = data.next().?;
        hand.bid = data.next().?;
        try hands.append(hand);
    }

    const hands_slice = hands.items;
    std.mem.sort(Player, hands_slice, {}, sortHands);

    var total: u64 = 0;
    for (hands_slice, 1..) |hand, i| {
        std.debug.print("Hand {d}: {s} ({s})\n", .{ i, hand.hand, hand.bid });
        const bid = try std.fmt.parseInt(u64, hand.bid, 10);
        total += bid * @as(u64, @intCast(i));
    }
    std.debug.print("Total: {d}\n", .{total});
}

fn calculateHand(hand: []const u8) HandType {
    var checked = [5]bool{ false, false, false, false, false };
    var jokers: u32 = 0;

    var pairs: u32 = 0;
    var triples: u32 = 0;
    var quadruples: u32 = 0;
    var quintuples: u32 = 0;

    for (0..5) |i| {
        if (hand[i] == 'J') {
            jokers += 1;
            continue;
        }
        if (checked[i]) continue;
        var count: u32 = 0;

        for (i..5) |j| {
            if (hand[i] == hand[j]) {
                checked[j] = true;
                count += 1;
            }
        }

        switch (count) {
            2 => pairs += 1,
            3 => triples += 1,
            4 => quadruples += 1,
            5 => quintuples += 1,
            else => {},
        }
    }

    //I'm not proud of this.
    if (quintuples == 1) {
        return HandType.FiveOfAKind;
    } else if (quadruples == 1) {
        if (jokers > 0) {
            return HandType.FiveOfAKind;
        }
        return HandType.FourOfAKind;
    } else if (triples == 1 and pairs == 1) {
        return HandType.FullHouse;
    } else if (triples == 1) {
        if (jokers == 1) {
            return HandType.FourOfAKind;
        } else if (jokers == 2) {
            return HandType.FiveOfAKind;
        }
        return HandType.ThreeOfAKind;
    } else if (pairs == 2) {
        if (jokers == 1) {
            return HandType.FullHouse;
        }
        return HandType.TwoPairs;
    } else if (pairs == 1) {
        if (jokers == 1) {
            return HandType.ThreeOfAKind;
        } else if (jokers == 2) {
            return HandType.FourOfAKind;
        } else if (jokers == 3) {
            return HandType.FiveOfAKind;
        }
        return HandType.OnePair;
    } else {
        if (jokers == 1) {
            return HandType.OnePair;
        } else if (jokers == 2) {
            return HandType.ThreeOfAKind;
        } else if (jokers == 3) {
            return HandType.FourOfAKind;
        } else if (jokers == 4) {
            return HandType.FiveOfAKind;
        } else if (jokers == 5) {
            return HandType.FiveOfAKind;
        }
        return HandType.HighCard;
    }
}

fn calculateHigherValue(hand_a: []const u8, hand_b: []const u8) bool {
    for (0..hand_a.len) |i| {
        if (hand_a[i] != hand_b[i]) {
            return symbolToValue(hand_a[i]) < symbolToValue(hand_b[i]);
        }
    }
    unreachable;
}

fn symbolToValue(s: u8) u8 {
    switch (s) {
        'J' => return 1,
        '2' => return 2,
        '3' => return 3,
        '4' => return 4,
        '5' => return 5,
        '6' => return 6,
        '7' => return 7,
        '8' => return 8,
        '9' => return 9,
        'T' => return 10,
        'Q' => return 12,
        'K' => return 13,
        'A' => return 14,
        else => unreachable,
    }
}

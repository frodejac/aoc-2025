const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = std.heap.c_allocator;

    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day05.txt", 1024 * 1024);
    defer allocator.free(input);

    const t0 = try std.time.Instant.now();
    const part1 = try solvePart1(allocator, input);
    const t1 = try std.time.Instant.now();

    const elapsedPart1 = t1.since(t0);
    const elapsedPart1Millis: f64 = @as(f64, @floatFromInt(elapsedPart1)) / 1000000.0;

    std.debug.print("Part 1: {d} ({d}ns, {d:.3}ms)\n", .{ part1, elapsedPart1, elapsedPart1Millis });

    const t2 = try std.time.Instant.now();
    const part2 = try solvePart2(allocator, input);
    const t3 = try std.time.Instant.now();
    const elapsedPart2 = t3.since(t2);
    const elapsedPart2Millis: f64 = @as(f64, @floatFromInt(elapsedPart2)) / 1000000.0;
    std.debug.print("Part 2: {d} ({d}ns, {d:.3}ms)\n", .{ part2, elapsedPart2, elapsedPart2Millis });
}

fn rangeSorter(_: void, lhs: [2]u64, rhs: [2]u64) bool {
    if (lhs[0] == rhs[0]) {
        return lhs[1] < rhs[1];
    }
    return lhs[0] < rhs[0];
}

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const rangeStrings = sections.next();
    const itemIdStrings = sections.next();
    var it = std.mem.tokenizeScalar(u8, rangeStrings.?, '\n');
    var ranges = try std.ArrayList([2]u64).initCapacity(allocator, 1024);
    defer ranges.deinit(allocator);
    while (it.next()) |rangeStr| {
        var r = std.mem.splitScalar(u8, rangeStr, '-');
        var range: [2]u64 = undefined;
        var i: usize = 0;
        while (r.next()) |num| {
            range[i] = try std.fmt.parseInt(u64, num, 10);
            i += 1;
        }
        std.debug.assert(range[0] <= range[1]);
        try ranges.append(allocator, range);
    }
    // Sort ranges
    std.mem.sort([2]u64, ranges.items, {}, rangeSorter);
    var curMin = ranges.items[0][0];
    var curMax = ranges.items[0][1];
    var writeIdx: usize = 0;
    for (ranges.items[1..]) |range| {
        // All ranges are sorted, so if the next range starts before
        // our current range ends, we extend the current range
        if (range[0] <= curMax) {
            curMax = @max(curMax, range[1]);
        } else {
            // disjoint range, store count and swap current range
            // reuse existing allocated memory by writing to writeIdx
            ranges.items[writeIdx] = [2]u64{ curMin, curMax };
            writeIdx += 1;
            curMin = range[0];
            curMax = range[1];
        }
    }
    ranges.items[writeIdx] = [2]u64{ curMin, curMax };
    writeIdx += 1;
    it = std.mem.tokenizeScalar(u8, itemIdStrings.?, '\n');
    var items = std.ArrayList(u64).empty;
    defer items.deinit(allocator);
    while (it.next()) |itemStr| {
        const itemId = try std.fmt.parseInt(u64, itemStr, 10);
        try items.append(allocator, itemId);
    }
    var count: u64 = 0;
    const mergedRanges = ranges.items[0..writeIdx];
    for (items.items) |item| {
        // Binary search
        var low: usize = 0;
        var high: usize = mergedRanges.len;
        while (low < high) {
            const mid = (low + high) / 2;
            const range = mergedRanges[mid];
            if (item < range[0]) {
                high = mid;
            } else if (item > range[1]) {
                low = mid + 1;
            } else {
                count += 1;
                break;
            }
        }
    }

    return count;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const rangeStrings = sections.next();
    var it = std.mem.tokenizeScalar(u8, rangeStrings.?, '\n');
    var ranges = std.ArrayList([2]u64).empty;
    defer ranges.deinit(allocator);
    while (it.next()) |rangeStr| {
        var r = std.mem.splitScalar(u8, rangeStr, '-');
        var range: [2]u64 = undefined;
        var i: usize = 0;
        while (r.next()) |num| {
            range[i] = try std.fmt.parseInt(u64, num, 10);
            i += 1;
        }
        std.debug.assert(range[0] <= range[1]);
        try ranges.append(allocator, range);
    }
    // Sort ranges by start value
    std.mem.sort([2]u64, ranges.items, {}, rangeSorter);

    // Here, we don't actually have to merge the ranges and keep them
    // for later, we just need to know the start/end points of all
    // disjoint ranges
    var count: u64 = 0;
    var curMin = ranges.items[0][0];
    var curMax = ranges.items[0][1];
    for (ranges.items[1..]) |range| {
        // All ranges are sorted, so if the next range starts before
        // our current range ends, we extend the current range
        if (range[0] <= curMax) {
            curMax = @max(curMax, range[1]);
        } else { // disjoint range, store count and swap current range
            count += curMax - curMin + 1;
            curMin = range[0];
            curMax = range[1];
        }
    }
    // Add up the final range as well
    count += curMax - curMin + 1;
    return count;
}

test "part 1 example" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 3), result);
}

test "part 2 example" {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 14), result);
}

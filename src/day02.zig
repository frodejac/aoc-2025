const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day02.txt", 1024 * 1024);
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

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    _ = allocator;
    const trimmed = std.mem.trimEnd(u8, input, "\n");
    var it = std.mem.tokenizeScalar(u8, trimmed, ',');
    var sum: u64 = 0;
    while (it.next()) |token| {
        var i: u8 = 0;
        var range: [2]u64 = undefined;
        var it2 = std.mem.splitScalar(u8, token, '-');
        while (it2.next()) |num| {
            range[i] = try std.fmt.parseInt(u64, num, 10);
            i += 1;
        }

        var min: u64 = range[0];
        var max: u64 = range[1];

        var minLength = std.math.log10_int(min) + 1;
        var maxLength = std.math.log10_int(max) + 1;

        // Clamp min to first even length digit in sequence
        if (minLength % 2 == 1) {
            minLength += 1;
            min = std.math.pow(u64, 10, minLength - 1); // 333 -> 1000, 33333 -> 100000
        }

        // Clamp max to last even length digit in sequence
        if (maxLength % 2 == 1) {
            maxLength -= 1;
            max = std.math.pow(u64, 10, maxLength) - 1; // 333 -> 99, 33333 -> 9999
        }

        // If the range only contains numbers of equal, odd length, there are no repeats possible
        if (max < min) {
            continue;
        }

        var value = @divFloor(min, std.math.pow(u64, 10, (minLength / 2)));
        var valueLength = std.math.log10_int(value) + 1;

        // if valuelength is odd, go to next even length

        var id: u64 = value * std.math.pow(u64, 10, valueLength) + value;
        while (id < min) {
            value += 1;
            valueLength = std.math.log10_int(value) + 1;
            id = value * std.math.pow(u64, 10, valueLength) + value;
        }

        while (id <= max) {
            sum += id;
            value += 1;
            valueLength = std.math.log10_int(value) + 1;
            id = value * std.math.pow(u64, 10, valueLength) + value;
        }
    }
    return sum;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const trimmed = std.mem.trimEnd(u8, input, "\n");
    var it = std.mem.tokenizeScalar(u8, trimmed, ',');
    var sum: u64 = 0;
    while (it.next()) |token| {
        var i: u8 = 0;
        var range: [2]u64 = undefined;
        var it2 = std.mem.splitScalar(u8, token, '-');
        while (it2.next()) |num| {
            range[i] = try std.fmt.parseInt(u64, num, 10);
            i += 1;
        }
        const min: u64 = range[0];
        const max: u64 = range[1];
        const rangesum = try sumInvalidInRange(allocator, min, max);
        sum += rangesum;
    }
    return sum;
}

fn sumInvalidInRange(alloc: std.mem.Allocator, min: u64, max: u64) !u64 {
    // The function for generating a number consisting of
    // only a number b with k digits repeating r times looks like
    // this:
    //
    //        N = b * ((10**(k*r))/(10**r))
    //
    // We can iterate through b, k, r values to generate numbers.
    // Using the digit length of the min/max values, we can set
    // b, k, r such that the values generated fall within the min/max
    // range.

    // I was unable to find a way to both avoid duplicates and generate the complete set of numbers
    // comprised of repeating sequences, so hashmap to the rescue. Using void as the value type
    // practically turns the hashmap into a set.
    var invalid = std.AutoHashMap(u64, void).init(alloc);
    defer invalid.deinit();

    const lenMin = std.math.log10_int(min) + 1;
    const lenMax = std.math.log10_int(max) + 1;

    for (lenMin..lenMax + 1) |d| { // iterate over all digit lengths in range
        for (2..d + 1) |r| { // iterate over all possible repitions for a given digit length
            if (d % r != 0) {
                continue; // skip repitions that aren't a factor of the digit length
            }
            const k = d / r; // digit length of the repeating block (e.g. for 123123123 we have d = 9, r = 3, k = 3)
            const m = (std.math.pow(u64, 10, d) - 1) / (std.math.pow(u64, 10, k) - 1);
            // We want all b such that min <= b*m <= max, that is min/m <= b <= max/m
            // But b must also be a k-digit number, meaning 10**(k-1) <= b <= 10**k-1
            // This means we can use whatever is largest of 10**(k-1) and ceil(min/m) as the lower bound
            // and the smallest of 10**k-1 and floor(max/m) as the upper bound
            const bmin = @max(std.math.pow(u64, 10, k - 1), (min + m - 1) / m); // ceil(min/m)
            const bmax = @min(std.math.pow(u64, 10, k) - 1, max / m);

            for (bmin..bmax + 1) |b| {
                const n = b * m;
                if (min <= n and n <= max) {
                    try invalid.put(n, {});
                }
            }
        }
    }
    var sum: u64 = 0;
    var it = invalid.keyIterator();
    while (it.next()) |n| {
        sum += n.*;
    }
    return sum;
}

test "part 1 example" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 1227775554), result);
}

test "part 2 example" {
    const input =
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 4174379265), result);
}

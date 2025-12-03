const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day03.txt", 1024 * 1024);
    defer allocator.free(input);

    const t0 = try std.time.Instant.now();
    const part1 = try solvePart1(allocator, input);
    const t1 = try std.time.Instant.now();

    const elapsedPart1 = t1.since(t0);

    std.debug.print("Part 1: {d} ({d}ns)\n", .{ part1, elapsedPart1 });

    const t2 = try std.time.Instant.now();
    const part2 = try solvePart2(allocator, input);
    const t3 = try std.time.Instant.now();
    const elapsedPart2 = t3.since(t2);
    std.debug.print("Part 2: {d} ({d}ns)\n", .{ part2, elapsedPart2 });
}

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    _ = allocator;
    var lineIt = std.mem.tokenizeScalar(u8, input, '\n');
    var sum: u64 = 0;
    while (lineIt.next()) |line| {
        var indexes = [2]u64{ line.len - 2, line.len - 1 };
        var maxIdx: u64 = 0;
        for (0..2) |i| {
            var j = indexes[i];
            while (j > maxIdx) {
                j -= 1;
                if (line[j] >= line[indexes[i]]) {
                    indexes[i] = j;
                }
            }
            maxIdx = indexes[i] + 1;
        }

        var jolt: u64 = 0;
        for (0..2) |i| {
            jolt += (line[indexes[i]] - 48) * std.math.pow(u64, 10, 2 - i - 1);
        }

        sum += jolt;
    }
    return sum;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    _ = allocator;
    var lineIt = std.mem.tokenizeScalar(u8, input, '\n');
    var sum: u64 = 0;
    while (lineIt.next()) |line| {
        var indexes = [12]u64{ line.len - 12, line.len - 11, line.len - 10, line.len - 9, line.len - 8, line.len - 7, line.len - 6, line.len - 5, line.len - 4, line.len - 3, line.len - 2, line.len - 1 };
        var maxIdx: u64 = 0;
        for (0..12) |i| {
            var j = indexes[i];
            while (j > maxIdx) {
                j -= 1;
                if (line[j] >= line[indexes[i]]) {
                    indexes[i] = j;
                }
            }
            maxIdx = indexes[i] + 1;
        }

        var jolt: u64 = 0;
        for (0..12) |i| {
            jolt += (line[indexes[i]] - 48) * std.math.pow(u64, 10, 12 - i - 1);
        }

        sum += jolt;
    }
    return sum;
}

test "part 1 example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 357), result);
}

test "part 2 example" {
    const input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 3121910778619), result);
}

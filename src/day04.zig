const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day04.txt", 1024 * 1024);
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
    // We don't know the size of the input before parsing it, so allocating
    // some extra memory for the 0-padding
    var img = try allocator.alloc(u8, input.len * 2);
    defer allocator.free(img);
    // Zeroing the allocated memory ensures we pad with 0's
    @memset(img, 0);

    // Parse input into 0-padded array, converting to '@' to 1
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var cursor: u64 = 1;
    var row: u64 = 1;
    var xdim: u64 = 0;
    var first: bool = true;
    while (it.next()) |line| {
        if (first) {
            xdim = line.len + 2;
            first = false;
        }
        const rowPos = row * xdim;
        for (line) |char| {
            img[rowPos + cursor] = @intFromBool(char == '@');
            cursor += 1;
        }
        row += 1;
        cursor = 1;
    }
    const ydim = row + 1;
    var sum: u64 = 0;

    // Perform our discrete convolution-like check,
    // using a 3x3 kernel:
    //
    //    (1, 1, 1)
    //    (1, 0, 1)
    //    (1, 1, 1)
    //
    // on each non-zero element
    for (1..ydim - 1) |y| {
        for (1..xdim - 1) |x| {
            if (img[y * xdim + x] != 1) {
                continue;
            }
            // Because of 0-padding we can ignore bounds-checks
            const kernelSum =
                img[(y - 1) * xdim + x - 1] +
                img[(y - 1) * xdim + x] +
                img[(y - 1) * xdim + x + 1] +
                img[y * xdim + x - 1] +
                img[y * xdim + x + 1] +
                img[(y + 1) * xdim + x - 1] +
                img[(y + 1) * xdim + x] +
                img[(y + 1) * xdim + x + 1];

            if (kernelSum < 4) {
                sum += 1;
            }
        }
    }
    return sum;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    // Setup is exactly equal to part 1
    var img = try allocator.alloc(u8, input.len * 2);
    defer allocator.free(img);
    @memset(img, 0);
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var cursor: u64 = 1;
    var row: u64 = 1;
    var xdim: u64 = 0;
    var first: bool = true;
    while (it.next()) |line| {
        if (first) {
            xdim = line.len + 2;
            first = false;
        }
        const rowPos = row * xdim;
        for (line) |char| {
            img[rowPos + cursor] = @intFromBool(char == '@');
            cursor += 1;
        }
        row += 1;
        cursor = 1;
    }
    const ydim = row + 1;

    // Do a sort of morphological erosion by removing all values that
    // satisfy the condition
    var total: u64 = 0;
    while (true) {
        var sum: u64 = 0;
        for (1..ydim - 1) |y| {
            for (1..xdim - 1) |x| {
                if (img[y * xdim + x] != 1) {
                    continue;
                }

                const kernelSum =
                    img[(y - 1) * xdim + x - 1] +
                    img[(y - 1) * xdim + x] +
                    img[(y - 1) * xdim + x + 1] +
                    img[y * xdim + x - 1] +
                    img[y * xdim + x + 1] +
                    img[(y + 1) * xdim + x - 1] +
                    img[(y + 1) * xdim + x] +
                    img[(y + 1) * xdim + x + 1];

                if (kernelSum < 4) {
                    sum += 1;
                    // Modify value in place
                    img[y * xdim + x] = 0;
                }
            }
        }
        // If the image stops changing, we're done
        if (sum == 0) {
            break;
        }
        total += sum;
    }
    return total;
}

test "part 1 example" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 13), result);
}

test "part 2 example" {
    const input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(@as(u64, 43), result);
}

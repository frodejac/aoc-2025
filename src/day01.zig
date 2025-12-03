const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "input/day01.txt", 1024 * 1024);
    defer allocator.free(input);

    const t0 = try std.time.Instant.now();
    const part1 = try solvePart1(allocator, input);
    const t1 = try std.time.Instant.now();

    const elapsedPart1 = t1.since(t0) / 1000;

    std.debug.print("Part 1: {d} ({d}us)\n", .{ part1, elapsedPart1 });

    const t2 = try std.time.Instant.now();
    const part2 = try solvePart2(allocator, input);
    const t3 = try std.time.Instant.now();
    const elapsedPart2 = t3.since(t2) / 1000;
    std.debug.print("Part 2: {d} ({d}us)\n", .{ part2, elapsedPart2 });
}

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var state: i32 = 50;
    var counter: i32 = 0;

    while (it.next()) |token| {
        const direction = token[0];
        var value = try std.fmt.parseInt(i32, token[1..], 10);
        if (direction == 'L') {
            value = -value;
        }
        state += value;
        state = @mod(state, 100);
        if (state == 0) {
            counter += 1;
        }
    }
    return counter;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    var state: i32 = 50;
    var counter: i32 = 0;

    while (it.next()) |token| {
        const direction = token[0];
        var value = try std.fmt.parseInt(i32, token[1..], 10);
        if (direction == 'L') {
            value = -value;
        }

        const remainder = @rem(value, 100);
        const fullRotations: i32 = @intCast(@abs(@divTrunc(value, 100)));
        var incr: i32 = 0;

        // Make sure not to count 'leaving' 0 as another 'crossing'
        if ((state != 0) and (state + remainder <= 0)) {
            incr += 1;
        } else if (state + remainder >= 100) {
            incr += 1;
        }

        counter += incr + fullRotations;
        state = @mod(state + remainder, 100);
    }

    return counter;
}

test "part 1 example" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try solvePart1(std.testing.allocator, input);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "part 2 example" {
    const input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try solvePart2(std.testing.allocator, input);
    try std.testing.expectEqual(@as(i64, 6), result);
}

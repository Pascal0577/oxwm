const std = @import("std");
const testing = std.testing;

const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
};

fn calculate_master_stack_layout(
    area: Rect,
    num_clients: usize,
    num_master: usize,
    master_factor: f32,
    gap: i32,
) []Rect {
    var rects: [16]Rect = undefined;
    if (num_clients == 0) return rects[0..0];

    const actual_master = @min(num_master, num_clients);
    const stack_count = if (num_clients > actual_master) num_clients - actual_master else 0;

    const master_width: i32 = if (stack_count > 0)
        @intFromFloat(@as(f32, @floatFromInt(area.w - gap)) * master_factor)
    else
        area.w;

    var i: usize = 0;
    while (i < actual_master) : (i += 1) {
        const h = @divTrunc(area.h - @as(i32, @intCast(actual_master - 1)) * gap, @as(i32, @intCast(actual_master)));
        rects[i] = .{
            .x = area.x,
            .y = area.y + @as(i32, @intCast(i)) * (h + gap),
            .w = master_width,
            .h = h,
        };
    }

    const stack_width = area.w - master_width - gap;
    var j: usize = 0;
    while (j < stack_count) : (j += 1) {
        const h = @divTrunc(area.h - @as(i32, @intCast(stack_count - 1)) * gap, @as(i32, @intCast(stack_count)));
        rects[actual_master + j] = .{
            .x = area.x + master_width + gap,
            .y = area.y + @as(i32, @intCast(j)) * (h + gap),
            .w = stack_width,
            .h = h,
        };
    }

    return rects[0..num_clients];
}

test "tiling layout: single window fills area" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_master_stack_layout(area, 1, 1, 0.55, 5);

    try testing.expectEqual(@as(usize, 1), rects.len);
    try testing.expectEqual(@as(i32, 0), rects[0].x);
    try testing.expectEqual(@as(i32, 0), rects[0].y);
    try testing.expectEqual(@as(i32, 800), rects[0].w);
    try testing.expectEqual(@as(i32, 600), rects[0].h);
}

test "tiling layout: two windows split horizontally" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_master_stack_layout(area, 2, 1, 0.5, 0);

    try testing.expectEqual(@as(usize, 2), rects.len);
    try testing.expectEqual(@as(i32, 400), rects[0].w);
    try testing.expectEqual(@as(i32, 400), rects[1].w);
}

test "tiling layout: respects master factor" {
    const area = Rect{ .x = 0, .y = 0, .w = 1000, .h = 600 };
    const rects = calculate_master_stack_layout(area, 2, 1, 0.6, 0);

    try testing.expectEqual(@as(usize, 2), rects.len);
    try testing.expectEqual(@as(i32, 600), rects[0].w);
    try testing.expectEqual(@as(i32, 400), rects[1].w);
}

test "tiling layout: no clients returns empty" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_master_stack_layout(area, 0, 1, 0.55, 5);

    try testing.expectEqual(@as(usize, 0), rects.len);
}

test "tiling layout: multiple stack windows divide height" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_master_stack_layout(area, 3, 1, 0.5, 0);

    try testing.expectEqual(@as(usize, 3), rects.len);
    try testing.expectEqual(@as(i32, 600), rects[0].h);
    try testing.expectEqual(@as(i32, 300), rects[1].h);
    try testing.expectEqual(@as(i32, 300), rects[2].h);
}

fn calculate_monocle_layout(area: Rect, num_clients: usize) []Rect {
    var rects: [16]Rect = undefined;
    if (num_clients == 0) return rects[0..0];

    var i: usize = 0;
    while (i < num_clients) : (i += 1) {
        rects[i] = area;
    }
    return rects[0..num_clients];
}

test "monocle layout: all windows get full area" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_monocle_layout(area, 3);

    try testing.expectEqual(@as(usize, 3), rects.len);
    for (rects) |rect| {
        try testing.expectEqual(@as(i32, 0), rect.x);
        try testing.expectEqual(@as(i32, 0), rect.y);
        try testing.expectEqual(@as(i32, 800), rect.w);
        try testing.expectEqual(@as(i32, 600), rect.h);
    }
}

test "monocle layout: no clients returns empty" {
    const area = Rect{ .x = 0, .y = 0, .w = 800, .h = 600 };
    const rects = calculate_monocle_layout(area, 0);

    try testing.expectEqual(@as(usize, 0), rects.len);
}

test "monocle layout: respects area offset" {
    const area = Rect{ .x = 100, .y = 50, .w = 800, .h = 600 };
    const rects = calculate_monocle_layout(area, 1);

    try testing.expectEqual(@as(i32, 100), rects[0].x);
    try testing.expectEqual(@as(i32, 50), rects[0].y);
}

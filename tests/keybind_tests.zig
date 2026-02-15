const std = @import("std");
const testing = std.testing;

const Mod4Mask: u32 = 1 << 6;
const Mod1Mask: u32 = 1 << 3;
const ShiftMask: u32 = 1 << 0;
const ControlMask: u32 = 1 << 2;

fn parse_modifier(name: []const u8) u32 {
    if (std.mem.eql(u8, name, "Mod4") or std.mem.eql(u8, name, "mod4") or std.mem.eql(u8, name, "super")) {
        return Mod4Mask;
    } else if (std.mem.eql(u8, name, "Mod1") or std.mem.eql(u8, name, "mod1") or std.mem.eql(u8, name, "alt")) {
        return Mod1Mask;
    } else if (std.mem.eql(u8, name, "Shift") or std.mem.eql(u8, name, "shift")) {
        return ShiftMask;
    } else if (std.mem.eql(u8, name, "Control") or std.mem.eql(u8, name, "control") or std.mem.eql(u8, name, "ctrl")) {
        return ControlMask;
    }
    return 0;
}

fn parse_modifiers(names: []const []const u8) u32 {
    var mask: u32 = 0;
    for (names) |name| {
        mask |= parse_modifier(name);
    }
    return mask;
}

test "parse_modifier: Mod4 variants" {
    try testing.expectEqual(Mod4Mask, parse_modifier("Mod4"));
    try testing.expectEqual(Mod4Mask, parse_modifier("mod4"));
    try testing.expectEqual(Mod4Mask, parse_modifier("super"));
}

test "parse_modifier: Mod1 (Alt) variants" {
    try testing.expectEqual(Mod1Mask, parse_modifier("Mod1"));
    try testing.expectEqual(Mod1Mask, parse_modifier("mod1"));
    try testing.expectEqual(Mod1Mask, parse_modifier("alt"));
}

test "parse_modifier: Shift variants" {
    try testing.expectEqual(ShiftMask, parse_modifier("Shift"));
    try testing.expectEqual(ShiftMask, parse_modifier("shift"));
}

test "parse_modifier: Control variants" {
    try testing.expectEqual(ControlMask, parse_modifier("Control"));
    try testing.expectEqual(ControlMask, parse_modifier("control"));
    try testing.expectEqual(ControlMask, parse_modifier("ctrl"));
}

test "parse_modifier: unknown returns 0" {
    try testing.expectEqual(@as(u32, 0), parse_modifier("Unknown"));
    try testing.expectEqual(@as(u32, 0), parse_modifier(""));
}

test "parse_modifiers: combines multiple modifiers" {
    const mods = &[_][]const u8{ "Mod4", "Shift" };
    try testing.expectEqual(Mod4Mask | ShiftMask, parse_modifiers(mods));
}

test "parse_modifiers: triple combination" {
    const mods = &[_][]const u8{ "super", "shift", "ctrl" };
    try testing.expectEqual(Mod4Mask | ShiftMask | ControlMask, parse_modifiers(mods));
}

test "parse_modifiers: empty list returns 0" {
    const mods = &[_][]const u8{};
    try testing.expectEqual(@as(u32, 0), parse_modifiers(mods));
}

fn key_name_to_keysym(name: []const u8) ?u64 {
    const key_map = .{
        .{ "Return", 0xff0d },
        .{ "Enter", 0xff0d },
        .{ "Tab", 0xff09 },
        .{ "Escape", 0xff1b },
        .{ "BackSpace", 0xff08 },
        .{ "Delete", 0xffff },
        .{ "space", 0x0020 },
        .{ "Space", 0x0020 },
    };

    inline for (key_map) |entry| {
        if (std.mem.eql(u8, name, entry[0])) {
            return entry[1];
        }
    }

    if (name.len == 1) {
        const char = name[0];
        if (char >= 'a' and char <= 'z') {
            return char;
        }
        if (char >= 'A' and char <= 'Z') {
            return char + 32;
        }
        if (char >= '0' and char <= '9') {
            return char;
        }
    }

    return null;
}

test "key_name_to_keysym: special keys" {
    try testing.expectEqual(@as(?u64, 0xff0d), key_name_to_keysym("Return"));
    try testing.expectEqual(@as(?u64, 0xff0d), key_name_to_keysym("Enter"));
    try testing.expectEqual(@as(?u64, 0xff09), key_name_to_keysym("Tab"));
    try testing.expectEqual(@as(?u64, 0xff1b), key_name_to_keysym("Escape"));
}

test "key_name_to_keysym: lowercase letters" {
    try testing.expectEqual(@as(?u64, 'a'), key_name_to_keysym("a"));
    try testing.expectEqual(@as(?u64, 'z'), key_name_to_keysym("z"));
}

test "key_name_to_keysym: uppercase converts to lowercase" {
    try testing.expectEqual(@as(?u64, 'a'), key_name_to_keysym("A"));
    try testing.expectEqual(@as(?u64, 'z'), key_name_to_keysym("Z"));
}

test "key_name_to_keysym: numbers" {
    try testing.expectEqual(@as(?u64, '0'), key_name_to_keysym("0"));
    try testing.expectEqual(@as(?u64, '9'), key_name_to_keysym("9"));
}

test "key_name_to_keysym: unknown returns null" {
    try testing.expectEqual(@as(?u64, null), key_name_to_keysym("UnknownKey"));
    try testing.expectEqual(@as(?u64, null), key_name_to_keysym(""));
}

test "key_name_to_keysym: space variants" {
    try testing.expectEqual(@as(?u64, 0x0020), key_name_to_keysym("space"));
    try testing.expectEqual(@as(?u64, 0x0020), key_name_to_keysym("Space"));
}

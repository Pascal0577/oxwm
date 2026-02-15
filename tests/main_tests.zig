const std = @import("std");

test {
    _ = @import("config_tests.zig");
    _ = @import("layout_tests.zig");
    _ = @import("keybind_tests.zig");
}

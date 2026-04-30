//! NetBSD implementation for getting IANA timezone

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    @compileError("NetBSD platform implementation not yet converted from Rust.");
}

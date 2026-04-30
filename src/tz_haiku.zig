//! Haiku implementation for getting IANA timezone
//!
//! Original Rust code used iana-time-zone-haiku crate

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    @compileError("Haiku platform implementation not yet converted from Rust.");
}

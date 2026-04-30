//! Android implementation for getting IANA timezone
//!
//! Original Rust code used android_system_properties crate
//! to read persist.sys.timezone system property

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    @compileError("Android platform implementation not yet converted from Rust. Original code used android_system_properties crate.");
}

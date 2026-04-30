//! Windows implementation for getting IANA timezone
//!
//! This implementation requires the Windows API (windows-core crate)
//! which cannot be directly called from Zig without manual FFI bindings.
//!
//! Original Rust code used: Windows::Globalization::Calendar

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    // Windows implementation requires windows-core FFI bindings
    // This cannot be directly converted to Zig without manual bindings
    @compileError("Windows platform not supported in Zig conversion. Original code used Windows.Globalization.Calendar API.");
}

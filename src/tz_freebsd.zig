//! FreeBSD implementation for getting IANA timezone
//!
//! FreeBSD uses similar mechanisms to Linux (zoneinfo)

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    // FreeBSD uses /etc/localtime similar to Linux
    // Could use same approach as tz_linux.zig once tested on FreeBSD
    @compileError("FreeBSD platform implementation not yet converted from Rust.");
}

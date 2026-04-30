//! get the IANA time zone for the current system
//!
//! This small utility provides the [`get_timezone()`] function.
//!
//! ```zig
//! // Get the current time zone as a string.
//! var tz = try iana_time_zone.get_timezone(std.heap.page_allocator);
//! defer std.heap.page_allocator.free(tz);
//! std.debug.print("The current time zone is: {s}\n", .{tz});
//! ```

const std = @import("std");
const builtin = @import("builtin");

// Error types for timezone retrieval
pub const GetTimezoneError = error{
    /// Unsupported operating system
    UnsupportedOS,
    /// Failed to read timezone from system
    OsError,
    /// Invalid timezone format
    InvalidFormat,
    /// IO error when reading files
    IoError,
};

/// Platform-specific implementations
const Platform = if (builtin.os.tag == .linux) struct {
    pub const get_timezone_inner = @import("tz_linux.zig").get_timezone_inner;
} else if (builtin.os.tag == .windows) struct {
    pub const get_timezone_inner = @import("tz_windows.zig").get_timezone_inner;
} else if (builtin.os.tag == .macos) struct {
    pub const get_timezone_inner = @import("tz_darwin.zig").get_timezone_inner;
} else if (builtin.os.tag == .freebsd) struct {
    pub const get_timezone_inner = @import("tz_freebsd.zig").get_timezone_inner;
} else if (builtin.os.tag == .netbsd) struct {
    pub const get_timezone_inner = @import("tz_netbsd.zig").get_timezone_inner;
} else if (builtin.os.tag == .illumos) struct {
    pub const get_timezone_inner = @import("tz_illumos.zig").get_timezone_inner;
} else if (builtin.os.tag == .aix) struct {
    pub const get_timezone_inner = @import("tz_aix.zig").get_timezone_inner;
} else if (builtin.os.tag == .haiku) struct {
    pub const get_timezone_inner = @import("tz_haiku.zig").get_timezone_inner;
} else struct {
    pub fn get_timezone_inner(_: std.mem.Allocator) GetTimezoneError![]u8 {
        @compileError("Unsupported operating system: " ++ @tagName(builtin.os.tag));
    }
};

/// Get the current IANA time zone as a string.
///
/// Returns the time zone name (e.g., "America/New_York", "Europe/London").
/// The caller must free the returned string using the provided allocator.
///
/// # Arguments
/// * `allocator` - The allocator to use for memory allocation
///
/// # Returns
/// The IANA time zone name as a heap-allocated string, or an error
pub fn get_timezone(allocator: std.mem.Allocator) GetTimezoneError![]u8 {
    return Platform.get_timezone_inner(allocator);
}

/// Get the current IANA time zone as a static string slice (null-terminated).
///
/// This is a convenience function that uses the global page allocator.
/// For production use, prefer `get_timezone()` with a specific allocator.
///
/// # Returns
/// The IANA time zone name as a slice, or an error
pub fn get_timezone_default() GetTimezoneError![]u8 {
    return Platform.get_timezone_inner(std.heap.page_allocator);
}

test "get_current_timezone" {
    const timezone = try get_timezone_default();
    defer std.heap.page_allocator.free(timezone);
    std.debug.print("Current timezone: {s}\n", .{timezone});
}

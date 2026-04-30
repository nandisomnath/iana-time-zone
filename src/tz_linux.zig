//! Linux implementation for getting IANA timezone

const std = @import("std");
const root = @import("root.zig");

/// Error type for timezone retrieval
const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    // Try /etc/localtime first (symlink), then /etc/timezone (text file)
    const result = etc_localtime(alloc) catch {
        return try etc_timezone(alloc);
    };
    return result;
}

/// Read timezone from /etc/timezone file
fn etc_timezone(alloc: std.mem.Allocator) TZError![]u8 {
    const file = std.fs.openFileAbsolute("/etc/timezone", .{}) catch {
        return error.OsError;
    };
    defer file.close();

    const stat = file.stat() catch {
        return error.IoError;
    };
    const size = stat.size;

    var buffer = alloc.alloc(u8, size) catch {
        return error.IoError;
    };
    defer alloc.free(buffer);

    const bytes_read = file.readAll(buffer) catch {
        return error.IoError;
    };

    // Trim whitespace
    var end = bytes_read;
    while (end > 0 and std.ascii.isWhitespace(buffer[end - 1])) {
        end -= 1;
    }

    return alloc.dupe(u8, buffer[0..end]) catch {
        return error.IoError;
    };
}

/// Read timezone from /etc/localtime symlink
fn etc_localtime(alloc: std.mem.Allocator) TZError![]u8 {
    // Per https://www.man7.org/linux/man-pages/man5/localtime.5.html:
    // The /etc/localtime file configures the system-wide timezone of the local system
    // that is used by applications for presentation to the user. It should be an
    // absolute or relative symbolic link pointing to /usr/share/zoneinfo/, followed by
    // a timezone identifier such as "Europe/Berlin" or "Etc/UTC".

    const PREFIXES = [_][]const u8{
        "/usr/share/zoneinfo/",
        "../usr/share/zoneinfo/",
        "/etc/zoneinfo/",
        "../etc/zoneinfo/",
    };

    // Read the symlink target
    var symlink_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const target_path = std.fs.readLinkAbsolute("/etc/localtime", symlink_buffer[0..]) catch {
        return error.OsError;
    };

    // Find the timezone by stripping the prefix
    for (PREFIXES) |prefix| {
        if (std.mem.startsWith(u8, target_path, prefix)) {
            const tz_slice = target_path[prefix.len..];
            return alloc.dupe(u8, tz_slice) catch {
                return error.IoError;
            };
        }
    }

    // If no known prefix found, return the full path as-is
    return alloc.dupe(u8, target_path) catch {
        return error.IoError;
    };
}

test "get_timezone_linux" {
    const tz = try get_timezone_inner(std.heap.page_allocator);
    defer std.heap.page_allocator.free(tz);
    std.debug.print("Timezone: {s}\n", .{tz});
}

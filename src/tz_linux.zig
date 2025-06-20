// use std::fs::{read_link, read_to_string};
const std = @import("std");

pub const TimeZomeError = error{GetTimeZoneError};

pub fn get_timezone_inner(alloc: std.mem.Allocator) ![]const u8 {
    const s = etc_localtime(alloc) catch etc_timezone(alloc) catch TimeZomeError.GetTimeZoneError;
    //     etc_localtime()
    //         .or_else(|_| etc_timezone())
    //         .or_else(|_| openwrt::etc_config_system())
    return s;
}

test "get time zone" {
    const buffer = try get_timezone_inner(std.heap.page_allocator);
    std.debug.print("{s}\n", .{buffer});
    std.heap.page_allocator.free(buffer);

}

/// it will return the string using heap.
/// You need to clean the buffer after use.
fn etc_timezone(alloc: std.mem.Allocator) ![]const u8 {
    // // see https://stackoverflow.com/a/12523283
    // let mut contents = read_to_string()?;
    var file = try std.fs.openFileAbsolute("/etc/timezone", .{});
    const stat = try file.stat();

    var buffer = try alloc.alloc(u8, stat.size);
    const length = try file.readAll(buffer);
    buffer = buffer[0..length];
    return buffer;
    // // Trim to the correct length without allocating.
    // contents.truncate(contents.trim_end().len());
    // Ok(contents)
}

fn etc_localtime(alloc: std.mem.Allocator) ![]const u8 {
    // Per <https://www.man7.org/linux/man-pages/man5/localtime.5.html>:
    // “ The /etc/localtime file configures the system-wide timezone of the local system that is
    //   used by applications for presentation to the user. It should be an absolute or relative
    //   symbolic link pointing to /usr/share/zoneinfo/, followed by a timezone identifier such as
    //   "Europe/Berlin" or "Etc/UTC". The resulting link should lead to the corresponding binary
    //   tzfile(5) timezone data for the configured timezone. ”

    // Systemd does not canonicalize the link, but only checks if it is prefixed by
    // "/usr/share/zoneinfo/" or "../usr/share/zoneinfo/". So we do the same.
    // <https://github.com/systemd/systemd/blob/9102c625a673a3246d7e73d8737f3494446bad4e/src/basic/time-util.c#L1493>

    const PREFIXES = [_][]const u8{
        "/usr/share/zoneinfo/", // absolute path
        "../usr/share/zoneinfo/", // relative path
        "/etc/zoneinfo/", // absolute path for NixOS
        "../etc/zoneinfo/", // relative path for NixOS
    };

    const buffer: *[std.fs.max_path_bytes]u8 = undefined;
    const s = try std.fs.readLinkAbsolute("/etc/localtime", buffer);

    var time_zone_buffer = try alloc.alloc(u8, s.len);
    for (PREFIXES) |prefix| {
        if (std.mem.startsWith(u8, s, prefix)) {
            const rlen = std.mem.replace(u8, s, prefix, "", time_zone_buffer);
            const len = s.len - prefix.len * rlen;
            return time_zone_buffer[0..len];
        }
    }

    return TimeZomeError.GetTimeZoneError;
}

// mod openwrt {
//     use std::io::BufRead;
//     use std::{fs, io, iter};

// pub fn etc_config_system() ![]const u8 {

// let f = fs::OpenOptions::new()
//     .read(true)
//     .open("/etc/config/system")?;
// let mut f = io::BufReader::new(f);
// let mut in_system_section = false;
// let mut line = String::with_capacity(80);

// // prefer option "zonename" (IANA time zone) over option "timezone" (POSIX time zone)
// let mut timezone = None;
// loop {
//     line.clear();
//     f.read_line(&mut line)?;
//     if line.is_empty() {
//         break;
//     }

//     let mut iter = IterWords(&line);
//     let mut next = || iter.next().transpose();

//     if let Some(keyword) = next()? {
//         if keyword == "config" {
//             in_system_section = next()? == Some("system") && next()?.is_none();
//         } else if in_system_section && keyword == "option" {
//             if let Some(key) = next()? {
//                 if key == "zonename" {
//                     if let (Some(zonename), None) = (next()?, next()?) {
//                         return Ok(zonename.to_owned());
//                     }
//                 } else if key == "timezone" {
//                     if let (Some(value), None) = (next()?, next()?) {
//                         timezone = Some(value.to_owned());
//                     }
//                 }
//             }
//         }
//     }
// }

// timezone.ok_or(crate::GetTimezoneError::OsError)
// }

// This is experimental do not uncomment it

// pub const GetTimezoneError = error{
//     IOError,
//     InvalidFormat,
//     NoOptionFound,
// };

// pub fn etc_config_system(alloc: std.mem.Allocator) ![]u8 {
//     const allocator = alloc;

//     // Open and buffer the file

//     const file = try std.fs.openFileAbsolute("/etc/config/system", .{});
//     defer file.close();

//     const reader = std.io.bufferedReader(file.reader());

//     var in_system_section = false;
//     var timezone: ?[]u8 = null;

//     while (true) {

//         const line = try reader.reader().readUntilDelimiterAlloc(allocator, '\n', std.heap.page_size_max);
//         if (line == null) break;

//         const trimmed = std.mem.trim(u8, line.?, " \t\r\n");

//         if (trimmed.len == 0) continue;

//         var it = std.mem.tokenize(u8, trimmed, " \t");

//         const keyword = it.next() orelse continue;

//         if (std.mem.eql(u8, keyword, "config")) {
//             const maybe_section = it.next();
//             const no_extra = it.next() == null;
//             in_system_section = maybe_section != null and
//                 std.mem.eql(u8, maybe_section.?, "system") and no_extra;
//         } else if (in_system_section and std.mem.eql(u8, keyword, "option")) {
//             const maybe_key = it.next();
//             const maybe_val = it.next();
//             const extra = it.next() != null;

//             if (maybe_key == null or maybe_val == null or extra) continue;

//             const key = maybe_key.?;
//             const val = maybe_val.?;

//             if (std.mem.eql(u8, key, "zonename")) {
//                 return try allocator.dupe(u8, val); // preferred, return immediately
//             } else if (std.mem.eql(u8, key, "timezone")) {
//                 if (timezone == null) {
//                     timezone = try allocator.dupe(u8, val); // store as fallback
//                 }
//             }
//         }

//         allocator.free(line.?); // manually free each line
//     }

//     if (timezone) |tz| {
//         return tz;
//     } else {
//         return GetTimezoneError.NoOptionFound;
//     }
// }

//     /// Read the next word in a OpenWRT config line. Strip any surrounding quotation marks.
//     ///
//     /// Returns
//     ///
//     ///  * a tuple `Some((word, remaining_line))` if found,
//     ///  * `None` if the line is exhausted, or
//     ///  * `Err(BrokenQuote)` if the line could not be parsed.
//     #[allow(clippy::manual_strip)] // needs to be compatile to 1.36
//     fn read_word(s: &str) -> Result<Option<(&str, &str)>, BrokenQuote> {
//         let s = s.trim_start();
//         if s.is_empty() || s.starts_with('#') {
//             Ok(None)
//         } else if s.starts_with('\'') {
//             let mut iter = s[1..].splitn(2, '\'');
//             match (iter.next(), iter.next()) {
//                 (Some(item), Some(tail)) => Ok(Some((item, tail))),
//                 _ => Err(BrokenQuote),
//             }
//         } else if s.starts_with('"') {
//             let mut iter = s[1..].splitn(2, '"');
//             match (iter.next(), iter.next()) {
//                 (Some(item), Some(tail)) => Ok(Some((item, tail))),
//                 _ => Err(BrokenQuote),
//             }
//         } else {
//             let mut iter = s.splitn(2, |c: char| c.is_whitespace());
//             match (iter.next(), iter.next()) {
//                 (Some(item), Some(tail)) => Ok(Some((item, tail))),
//                 _ => Ok(Some((s, ""))),
//             }
//         }
//     }

//     #[cfg(test)]
//     #[test]
//     fn test_read_word() {
//         assert_eq!(
//             read_word("       option timezone 'CST-8'\n").unwrap(),
//             Some(("option", "timezone 'CST-8'\n")),
//         );
//         assert_eq!(
//             read_word("timezone 'CST-8'\n").unwrap(),
//             Some(("timezone", "'CST-8'\n")),
//         );
//         assert_eq!(read_word("'CST-8'\n").unwrap(), Some(("CST-8", "\n")));
//         assert_eq!(read_word("\n").unwrap(), None);

//         assert_eq!(
//             read_word(r#""time 'Zone'""#).unwrap(),
//             Some(("time 'Zone'", "")),
//         );

//         assert_eq!(read_word("'CST-8").unwrap_err(), BrokenQuote);
//     }
// }

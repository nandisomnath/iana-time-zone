//! WebAssembly (wasm32-unknown) implementation for getting IANA timezone
//!
//! Original Rust code used js-sys and wasm-bindgen to access JavaScript Intl API

const std = @import("std");
const root = @import("root.zig");

const TZError = root.GetTimezoneError;

/// Get the current IANA time zone as a string
pub fn get_timezone_inner(alloc: std.mem.Allocator) TZError![]u8 {
    _ = alloc;
    @compileError("WebAssembly platform not yet converted from Rust. Original code used JavaScript Intl API.");
}

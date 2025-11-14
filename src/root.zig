const std = @import("std");

/// Compresses an unsorted sequence of |length| 32bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function does NOT use delta encoding.
extern fn vbyte_compress_unsorted32(
    in: [*]const u32,
    out: [*]u8,
    length: usize,
) usize;

/// Compresses an unsorted sequence of |length| 64bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function does NOT use delta encoding.
extern fn vbyte_compress_unsorted64(
    in: [*]const u64,
    out: [*]u8,
    length: usize,
) usize;

/// Compresses a sorted sequence of |length| 32bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
extern fn vbyte_compress_sorted32(
    in: [*]const u32,
    out: [*]u8,
    previous: u32,
    length: usize,
) usize;

/// Compresses a sorted sequence of |length| 64bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
extern fn vbyte_compress_sorted64(
    in: [*]const u64,
    out: [*]u8,
    previous: u64,
    length: usize,
) usize;

/// Uncompresses a sequence of |length| 32bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_unsorted32|. It does NOT use
/// delta encoding.
///
/// Returns the number of compressed bytes processed.
extern fn vbyte_uncompress_unsorted32(in: [*]const u8, out: [*]u32, length: usize) usize;

/// Uncompresses a sequence of |length| 64bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_unsorted64|. It does NOT use
/// delta encoding.
///
/// Returns the number of compressed bytes processed.
extern fn vbyte_uncompress_unsorted64(in: [*]const u8, out: [*]u64, length: usize) usize;

/// Uncompresses a sequence of |length| 32bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_sorted32|.
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
///
/// Returns the number of compressed bytes processed.
extern fn vbyte_uncompress_sorted32(
    in: [*]const u8,
    out: [*]u32,
    previous: u32,
    length: usize,
) usize;

/// Uncompresses a sequence of |length| 64bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_sorted64|.
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
///
/// Returns the number of compressed bytes processed.
extern fn vbyte_uncompress_sorted64(
    in: [*]const u8,
    out: [*]u64,
    previous: u64,
    length: usize,
) usize;

/// Upper bound of bytes needed on the compression output buffer
pub fn compress_bound(comptime T: type, length: usize) usize {
    return switch (T) {
        u32 => (@sizeOf(u32) + 1) * length,
        u64 => (@sizeOf(u64) + 2) * length,
        else => @compileError("unsupported type"),
    };
}

/// Returns the number of bytes written to `out`
pub fn compress_sorted(comptime T: type, in: []const T, out: []u8) usize {
    std.debug.assert(compress_bound(T, in.len) <= out.len);

    return switch (T) {
        u32 => vbyte_compress_sorted32(in.ptr, out.ptr, 0, in.len),
        u64 => vbyte_compress_sorted64(in.ptr, out.ptr, 0, in.len),
        else => @compileError("unsupported type"),
    };
}

pub fn decompress_sorted(comptime T: type, in: []const u8, out: []T) void {
    const n_read = switch (T) {
        u32 => vbyte_uncompress_sorted32(in.ptr, out.ptr, 0, out.len),
        u64 => vbyte_uncompress_sorted64(in.ptr, out.ptr, 0, out.len),
        else => @compileError("unsupported type"),
    };
    std.debug.assert(n_read == in.len);
}

/// Returns the number of bytes written to `out`
pub fn compress_unsorted(comptime T: type, in: []const T, out: []u8) usize {
    std.debug.assert(compress_bound(T, in.len) <= out.len);

    return switch (T) {
        u32 => vbyte_compress_unsorted32(in.ptr, out.ptr, in.len),
        u64 => vbyte_compress_unsorted64(in.ptr, out.ptr, in.len),
        else => @compileError("unsupported type"),
    };
}

pub fn decompress_unsorted(comptime T: type, in: []const u8, out: []T) void {
    const n_read = switch (T) {
        u32 => vbyte_uncompress_unsorted32(in.ptr, out.ptr, out.len),
        u64 => vbyte_uncompress_unsorted64(in.ptr, out.ptr, out.len),
        else => @compileError("unsupported type"),
    };
    std.debug.assert(n_read == in.len);
}

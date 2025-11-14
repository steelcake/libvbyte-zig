/// Compresses an unsorted sequence of |length| 32bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function does NOT use delta encoding.
pub extern fn vbyte_compress_unsorted32(
    in: [*]const u32,
    out: [*]u8,
    length: usize,
) usize;

/// Compresses an unsorted sequence of |length| 64bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function does NOT use delta encoding.
pub extern fn vbyte_compress_unsorted64(
    in: [*]const u64,
    out: [*]u8,
    length: usize,
) usize;

/// Compresses a sorted sequence of |length| 32bit unsigned integers
/// at |in| and stores the result in |out|.
///
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
pub extern fn vbyte_compress_sorted32(
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
pub extern fn vbyte_compress_sorted64(
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
pub extern fn vbyte_uncompress_unsorted32(in: [*]const u8, out: [*]u32, length: usize) usize;

/// Uncompresses a sequence of |length| 64bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_unsorted64|. It does NOT use
/// delta encoding.
///
/// Returns the number of compressed bytes processed.
pub extern fn vbyte_uncompress_unsorted64(in: [*]const u8, out: [*]u64, length: usize) usize;

/// Uncompresses a sequence of |length| 32bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_sorted32|.
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
///
/// Returns the number of compressed bytes processed.
pub extern fn vbyte_uncompress_sorted32(in: [*]const u8, out: [*]u32, previous: u32, length: usize,) usize;

/// Uncompresses a sequence of |length| 64bit unsigned integers at |in|
/// and stores the result in |out|.
///
/// This is the equivalent of |vbyte_compress_sorted64|.
/// This function uses delta encoding. Set |previous| to the initial value,
/// or 0.
///
/// Returns the number of compressed bytes processed.
pub extern fn vbyte_uncompress_sorted64(in: [*]const u8, out: [*]u64, previous: u64, length: usize,) usize;

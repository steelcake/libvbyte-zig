const std = @import("std");
const page_allocator = std.heap.page_allocator;

const libvbyte = @import("libvbyte");

const MAX_NUM_INTS = 1 << 20;

fn Context(comptime T: type) type {
    return struct {
        const Self = @This();

        input: []T,
        compressed: []u8,
        output: []T,

        pub fn init() Context(T) {
            const input = page_allocator.alloc(T, MAX_NUM_INTS) catch unreachable;
            const output = page_allocator.alloc(T, MAX_NUM_INTS) catch unreachable;
            const compressed = page_allocator.alloc(
                u8,
                libvbyte.compress_bound(T, MAX_NUM_INTS),
            ) catch unreachable;

            return .{
                .input = input,
                .output = output,
                .compressed = compressed,
            };
        }

        fn deinit(self: *Self) void {
            page_allocator.free(self.input);
            page_allocator.free(self.output);
            page_allocator.free(self.compressed);

            self.input = &.{};
            self.output = &.{};
            self.compressed = &.{};
        }
    };
}

fn read_input(comptime T: type, typed_input: []T, input: []const u8) []T {
    std.debug.assert(typed_input.len == MAX_NUM_INTS);

    const input_num_ints = input.len / @sizeOf(T);
    const num_ints = @min(input_num_ints, MAX_NUM_INTS);
    const num_bytes = @sizeOf(T) * num_ints;
    @memcpy(@as([]u8, @ptrCast(typed_input))[0..num_bytes], input[0..num_bytes]);

    return typed_input[0..num_ints];
}

fn Unsorted(comptime T: type) type {
    return struct {
        const size = @sizeOf(T);

        pub fn fuzz_one(ctx: Context(T), input: []const u8) anyerror!void {
            const in = read_input(T, ctx.input, input);

            const compressed_len = libvbyte.compress_unsorted(
                T,
                in,
                ctx.compressed,
            );

            std.debug.assert(
                compressed_len <= libvbyte.compress_bound(T, MAX_NUM_INTS),
            );

            libvbyte.uncompress_unsorted(
                T,
                ctx.compressed[0..compressed_len],
                ctx.output[0..in.len],
            );

            std.debug.assert(
                std.mem.eql(T, in, ctx.output[0..in.len]),
            );
        }
    };
}

fn Sorted(comptime T: type, comptime valid_input: bool) type {
    return struct {
        const size = @sizeOf(T);

        pub fn fuzz_one(ctx: Context(T), input: []const u8) anyerror!void {
            const in = read_input(T, ctx.input, input);

            if (valid_input) {
                std.mem.sortUnstable(T, in, {}, std.sort.asc(T));
            }

            const compressed_len = libvbyte.compress_sorted(
                T,
                in,
                ctx.compressed,
            );

            std.debug.assert(
                compressed_len <= libvbyte.compress_bound(T, MAX_NUM_INTS),
            );

            libvbyte.uncompress_sorted(
                T,
                ctx.compressed[0..compressed_len],
                ctx.output[0..in.len],
            );

            // Don't expect valid output if the input is invalid.
            // Just expect it to not crash before this point.
            if (valid_input) {
                std.debug.assert(
                    std.mem.eql(T, in, ctx.output[0..in.len]),
                );
            }
        }
    };
}

const Ctx32 = Context(u32);
const Ctx64 = Context(u64);

test "unsorted_32" {
    var ctx = Ctx32.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Unsorted(u32).fuzz_one, .{});
}

test "unsorted_64" {
    var ctx = Ctx64.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Unsorted(u64).fuzz_one, .{});
}

test "sorted_32" {
    var ctx = Ctx32.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Sorted(u32, true).fuzz_one, .{});
}

test "sorted_64" {
    var ctx = Ctx64.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Sorted(u64, true).fuzz_one, .{});
}

test "sorted_32_invalid" {
    var ctx = Ctx32.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Sorted(u32, false).fuzz_one, .{});
}

test "sorted_64_invalid" {
    var ctx = Ctx64.init();
    defer ctx.deinit();
    try std.testing.fuzz(ctx, Sorted(u64, false).fuzz_one, .{});
}

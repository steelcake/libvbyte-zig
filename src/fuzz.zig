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
            const compressed = page_allocator.alloc(u8, libvbyte.compress_bound(T, MAX_NUM_INTS)) catch unreachable;

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

fn Unsorted(comptime T: type) type {
    return struct {
        const size = @sizeOf(T);

        const compress = switch (T) {
            u32 => libvbyte.vbyte_compress_unsorted32,
            u64 => libvbyte.vbyte_compress_unsorted64,
            else => @compileError("unsupported type"),
        };

        const uncompress = switch (T) {
            u32 => libvbyte.vbyte_uncompress_unsorted32,
            u64 => libvbyte.vbyte_uncompress_unsorted64,
            else => @compileError("unsupported type"),
        };

        pub fn fuzz_one(ctx: Context(T), input: []const u8) anyerror!void {
            const input_num_ints = input.len / size * size;
            const num_ints = @min(input_num_ints, MAX_NUM_INTS);
            const num_bytes = size * num_ints;
            @memcpy(@as([]u8, @ptrCast(ctx.input))[0..num_bytes], input[0..num_bytes]);

            const compressed_len = compress(ctx.input.ptr, ctx.compressed.ptr, num_ints);

            std.debug.assert(compressed_len <= libvbyte.compress_bound(T, MAX_NUM_INTS));

            const n_read = uncompress(ctx.compressed.ptr, ctx.output.ptr, num_ints);
            std.debug.assert(n_read == num_bytes);

            std.debug.assert(std.mem.eql(T, ctx.input[0..num_ints], ctx.output[0..num_ints]));
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

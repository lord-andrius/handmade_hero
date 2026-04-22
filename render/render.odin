package render

import "../window"
import "core:mem"

draw_rect :: proc(window_context: window.Window_Context, x, y, width, height: i32, r, g, b: u8) {
    x := x if x < window_context.width else window_context.width
    y := y if y < window_context.height else window_context.height
    width := width if width <= window_context.width else window_context.width
    height := height if height <= window_context.height else window_context.height
    buffer_data := &window_context.buffer.data[y * window_context.stride + (x * window_context.bytes_per_pixel)]
	for y in 0..<width {
		pixel := transmute(^u32)buffer_data
		for x in 0..<height {
			pixel^ = 0x00 | (u32(r) << 8) | (u32(g) << 16) | (u32(b) << 24)
			pixel = mem.ptr_offset(pixel, 1)
		}
		buffer_data = mem.ptr_offset(buffer_data, window_context.stride)
	}
}
package main

import "window"
import "wayland"
import "core:fmt"
import "render"
import "core:time"

main :: proc() {
	if !window.init() {
        fmt.println("could not init window system")
        return
    }
    defer window.deinit()

    window.create_window(600, 400, "handmade")

    color: [3]u8
    color.r = 100
    color.g = 100
    color.b = 255
    t := time.now()
    for !window.window_should_close() {
        if window.isMouseReleased(.Left) || window.isMouseReleased(.Right) {
            fmt.println("Mouse released")
        }

        if window.isMouseDown(.Left) {
            color.r = 255
            color.g = 100
            color.b = 100
        } else if window.isMouseDown(.Right) {
            color.r = 100
            color.g = 255
            color.b = 100
        } else {
            color.r = 100
            color.g = 100
            color.b = 255
        }

    
        ctx := window.get_window_context()
        t = time.now()
        window.begin_drawing()
        window.clear_window()
        render.draw_rect(ctx, i32(ctx.mouseX), i32(ctx.mouseY), 100, 100, color.r, color.g, color.b)
        window.end_drawing()
        time_spend := time.diff(t, time.now())
        if time.duration_milliseconds(time_spend) < 16 {
            time.sleep(16e6)
        }
    }
}
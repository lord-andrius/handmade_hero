package main

import "window"
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

    xQ, yQ: i32 = 0, 0

    for !window.window_should_close() {
        if xQ > 200 {
            xQ = 0
        }

        if yQ > 200 {
            yQ = 0
        }
        t := time.now()
        window.begin_drawing()
        window.clear_window()
        ctx := window.get_window_context()
        render.draw_rect(ctx, xQ, yQ, 100, 100, 86, 86, 86)
        window.end_drawing()
        xQ += 1
        yQ += 1
        time_spend := time.diff(t, time.now())
        if time.duration_milliseconds(time_spend) < 16 {
            time.sleep(time.Duration(time.duration_milliseconds(time_spend) - 16) * 1000000)
            fmt.println(time.duration_milliseconds(time_spend))
        }

        fmt.println(time.duration_milliseconds(time.diff(t, time.now())))
    }
}
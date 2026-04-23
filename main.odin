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
    t := time.now()
    for !window.window_should_close() {
        ctx := window.get_window_context()
        if xQ > ctx.width {
            xQ = 0
            yQ += 30
        }

        if yQ > ctx.height {
            yQ = 0
        }
        t = time.now()
        window.begin_drawing()
        window.clear_window()
        render.draw_rect(ctx, xQ, yQ, 100, 100, 255, 0, 0)
        window.end_drawing()
        xQ += 30
        time_spend := time.diff(t, time.now())
        if time.duration_milliseconds(time_spend) < 16 {
            time.sleep(16e6)
         //   fmt.println(time.duration_milliseconds(time_spend))
        }

        //fmt.println(time.duration_milliseconds(time.diff(t, time.now())))
    }
}
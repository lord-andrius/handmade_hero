package main

import "window"
import "core:fmt"

main :: proc() {
	if !window.init() {
        fmt.println("could not init window system")
        return
    }
    defer window.deinit()

    window.create_window()


    for !window.window_should_close() {
        window.begin_drawing()
        window.clear_window()
        window.end_drawing()
    }
}
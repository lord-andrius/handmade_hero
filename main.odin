package main

import "base:runtime"
import "core:fmt"
import "core:image"
import "core:image/netpbm"
import "core:math/rand"
import "shared"
import "wayland"
import "window"


Window_Context :: struct {
	buffer:                   ^wayland.Wl_Buffer,
	wl_surface_id:            u32,
	xdg_surface_id:           u32,
	xdg_toplevel_id:          u32,
	has_been_congigured_once: bool,
}

window_context: Window_Context

wl_shm_id: u32 = 0
wl_compositor_id: u32 = 0
xdg_wm_base_id: u32 = 0


WIDTH :: 1440
HEIGHT :: 900
BYTES_PER_PIXEL :: 4

error_callback :: proc(
	user_data: rawptr,
	wl_display_id: u32,
	error_obj_id: u32,
	error: wayland.Global_Error,
	message: string,
) {
	fmt.printfln("%v %s", error, message)
}

handle_wl_shm_format_callback :: proc(
	user_data: rawptr,
	wl_shm_id: u32,
	format: wayland.Wl_Shm_Format,
) {
	fmt.println(format)
}


handle_global_callback :: proc(
	user_data: rawptr,
	wl_registry_id: u32,
	name: u32,
	interface: string,
	version: u32,
) {
	fmt.printfln("name: %d | interface: %s | version: %d", name, interface, version)
	if interface == "wl_shm" {
		wl_shm_id = wayland.bind_wl_shm_global_object(wl_registry_id, name, interface, version)
		wayland.wl_shm_set_format_callback(wl_shm_id, nil, handle_wl_shm_format_callback)
	} else if interface == "xdg_wm_base" {
		xdg_wm_base_id = wayland.bind_xdg_wm_base(wl_registry_id, name, interface, version)
	} else if interface == "wl_compositor" {
		wl_compositor_id = wayland.bind_wl_compsitor_global_object(
			wl_registry_id,
			name,
			interface,
			version,
		)
	}
}

handle_done_sync_callback :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
	deve_sair := transmute(^bool)user_data
	fmt.println("done")
	deve_sair^ = true
}

handle_xdg_surface_configure :: proc(user_data: rawptr, xdg_surface_id: u32, serial: u32) {
	fmt.println("xdg_surface_configure")
	if window_context.has_been_congigured_once {
		wayland.wl_surface_attach(window_context.wl_surface_id, window_context.buffer)
	}
	wayland.xdg_surface_set_window_geometry(window_context.xdg_surface_id, 0, 0, WIDTH, HEIGHT)
	wayland.wl_surface_commit(window_context.wl_surface_id)
	wayland.xdg_surface_ack_configure(xdg_surface_id, serial)
	if window_context.has_been_congigured_once == false {
		window_context.has_been_congigured_once = true
	}
}

acessar_pixel_por_cordenada :: proc(
	x: u32,
	y: u32,
	width: u32,
	height: u32,
	bytes_per_pixel: u32,
	data: []u8,
) -> []u8 {

	index := ((y * (width * bytes_per_pixel)) + (x * bytes_per_pixel))
	if int(index) >= len(data) {
		fmt.printfln(
			"x: %d | y : %d | width: %d | height: %d | index: %d",
			x,
			y,
			width,
			height,
			index,
		)
	}
	fmt.println("index =", index)
	return transmute([]u8)runtime.Raw_Slice{data = &data[index], len = int(bytes_per_pixel)}
}

main :: proc() {
	/*
	wayland.connect()
	wayland.wl_display_set_event_error_callback(error_callback, nil)

	registry, _ := wayland.wl_display_get_registry()

	wayland.wl_registry_set_event_global_callback(registry, handle_global_callback, nil)


	deve_sair := false
	wayland.wl_display_sync(handle_done_sync_callback, &deve_sair)

	for !deve_sair {
		msg, ok := wayland.read_message()
		defer delete(msg.arguments)
		id := wayland.get_message_object_id(msg)
		if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
			dispatch(msg)
		}
	}


	buffer, ok := shared.create_shared_buffer("handmade", (WIDTH * HEIGHT * BYTES_PER_PIXEL) * 2)
	assert(ok)
	defer shared.destroy_shared_buffer(buffer)

	pool, _ := wayland.wl_shm_create_pool(wl_shm_id, buffer, len(buffer.data))

	window_context.buffer, _ = wayland.wl_shm_pool_create_buffer(
		&pool,
		0,
		WIDTH,
		HEIGHT,
		WIDTH * BYTES_PER_PIXEL,
		.xrgb8888,
	)
	deve_sair = false

	image_data, _ := image.load_from_file("res/teste.ppm")
	defer image.destroy(image_data)

	for &p in window_context.buffer.data {
		p = 0xFF
	}


	image_size := image_data.width * image_data.height

	for y in 0 ..< image_data.height {
		for x in 0 ..< image_data.width {

			impx := acessar_pixel_por_cordenada(
				u32(x),
				u32(y),
				u32(image_data.width),
				u32(image_data.height),
				3,
				image_data.pixels.buf[:],
			)
			buffer_pixel := acessar_pixel_por_cordenada(
				u32(x),
				u32(y),
				WIDTH,
				HEIGHT,
				4,
				window_context.buffer.data,
			)
			buffer_pixel[0] = impx[0]
			buffer_pixel[1] = impx[1]
			buffer_pixel[2] = impx[2]
			buffer_pixel[3] = impx[2]
		}
	}


	window_context.wl_surface_id = wayland.wl_compositor_create_surface(wl_compositor_id)
	defer wayland.wl_surface_destroy(window_context.wl_surface_id)

	window_context.xdg_surface_id, _ = wayland.xdg_wm_base_get_xdg_surface(
		xdg_wm_base_id,
		window_context.wl_surface_id,
	)
	defer wayland.xdg_surface_destroy(window_context.xdg_surface_id)
	wayland.xdg_surface_set_configure_callback(
		window_context.xdg_surface_id,
		nil,
		handle_xdg_surface_configure,
	)


	handle_close :: proc(user_data: rawptr, xdg_toplevel_id: u32) {
		deve_sair := transmute(^bool)user_data
		fmt.println("saindo...")
		deve_sair^ = true
	}

	window_context.xdg_toplevel_id, _ = wayland.xdg_surface_get_toplevel(
		window_context.xdg_surface_id,
	)
	defer wayland.xdg_toplevel_destroy(window_context.xdg_toplevel_id)
	wayland.xdg_toplevel_set_close_callback(
		window_context.xdg_toplevel_id,
		&deve_sair,
		handle_close,
	)


	wayland.wl_surface_commit(window_context.wl_surface_id)
	window_context.has_been_congigured_once = true


	//wayland.wl_display_sync(handle_done_sync_callback, &deve_sair)

	for !deve_sair {
		msg, ok := wayland.read_message()
		defer delete(msg.arguments)
		id := wayland.get_message_object_id(msg)
		if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
			dispatch(msg)
		}
	}
	*/

	window.initialize()

	if window.create_window({
		title = "Handmade",
		width = 1280,
		height = 720,
		flags = {.resizable},
		bytes_per_pixel = 4,
		pixel_format = .xrgb8888
	}) == false {
		fmt.println("could not create window")
		return 
	}

	should_close := false

	for !should_close {
		event: window.Event
		for window.read_event(&event) {
			switch e in event {
				case window.Close_Event:
					should_close = true
			}
		}
	}

}

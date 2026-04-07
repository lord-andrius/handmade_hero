package main

import "base:runtime"
import "core:image"
import "core:image/bmp"
import "core:fmt"
import "wayland"
import "core:math/rand"

import "shared"


Window_Context :: struct {
	buffer: ^wayland.Wl_Buffer,
	wl_surface_id: u32,
	xdg_surface_id: u32,
	xdg_toplevel_id: u32,
	has_been_congigured_once: bool,
}

window_context: Window_Context

wl_shm_id: u32 = 0
wl_compositor_id : u32 = 0
xdg_wm_base_id: u32 = 0


WIDTH :: 1440
HEIGHT :: 900
BYTES_PER_PIXEL :: 4

error_callback :: proc(user_data: rawptr, wl_display_id: u32, error_obj_id: u32, error: wayland.Global_Error, message: string) {
	fmt.printfln("%v %s", error, message)
}

handle_wl_shm_format_callback :: proc(user_data: rawptr, wl_shm_id: u32, format: wayland.Wl_Shm_Format) {
	fmt.println(format)
}


handle_global_callback :: proc(user_data: rawptr, wl_registry_id: u32, name: u32, interface: string, version: u32) {
	fmt.printfln("name: %d | interface: %s | version: %d", name, interface, version)
	if interface == "wl_shm" {
		wl_shm_id = wayland.bind_wl_shm_global_object(wl_registry_id, name, interface, version)
		wayland.wl_shm_set_format_callback(wl_shm_id, nil, handle_wl_shm_format_callback)
	} else if interface == "xdg_wm_base" {
		xdg_wm_base_id = wayland.bind_xdg_wm_base(wl_registry_id, name, interface, version)
	} else if interface == "wl_compositor" {
		wl_compositor_id = wayland.bind_wl_compsitor_global_object(wl_registry_id, name, interface, version) 
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

main :: proc() {
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

	//wl_buffer, _ := wayland.wl_shm_pool_create_buffer(&pool, 0, WIDTH, HEIGHT, WIDTH * BYTES_PER_PIXEL, .argb8888)
	//defer wayland.wl_buffer_destroy(wl_buffer)
 
	wayland.wl_shm_pool_resize(&pool, 1920*1080*2*4)

	window_context.buffer, _ = wayland.wl_shm_pool_create_buffer(&pool, 0, WIDTH, HEIGHT, WIDTH * BYTES_PER_PIXEL, .xrgb8888)
	deve_sair = false

	for &p in window_context.buffer.data {
		p = u8(rand.int64_range(0, 255))
	}


	window_context.wl_surface_id = wayland.wl_compositor_create_surface(wl_compositor_id)
	defer wayland.wl_surface_destroy(window_context.wl_surface_id)

	window_context.xdg_surface_id, _ = wayland.xdg_wm_base_get_xdg_surface(xdg_wm_base_id, window_context.wl_surface_id)
	defer wayland.xdg_surface_destroy(window_context.xdg_surface_id)
	wayland.xdg_surface_set_configure_callback(window_context.xdg_surface_id, nil, handle_xdg_surface_configure)
	
	
	window_context.xdg_toplevel_id, _ = wayland.xdg_surface_get_toplevel(window_context.xdg_surface_id)
	defer wayland.xdg_toplevel_destroy(window_context.xdg_toplevel_id)
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

	
}

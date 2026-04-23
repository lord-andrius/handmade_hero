package window

import "vendor:windows/XAudio2"
import "core:fmt"
import "../wayland"
import "../shared"
import "core:sys/linux"
import "core:mem"
import "core:strings"


Window_Context :: struct {
	window_should_close: bool,

	//ids
	wl_compositor_id: u32,
	wl_shm_id: u32,
	xdg_wm_base_id: u32,
	wl_surface_id: u32,
	xdg_surface_id: u32,
	xdg_toplevel_id: u32,
	zxdg_decoration_manager_v1_id: u32,
	zxdg_toplevel_decoration_id: u32,
	wl_seat_id: u32,
	wl_pointer_id: u32,
	wl_keyboard_id: u32,
	// fim ids
	available_formats: [dynamic;64]wayland.Wl_Shm_Format,
	width: i32,
	height: i32,
	stride: i32,
	size:   i32,
	format: wayland.Wl_Shm_Format,
	bytes_per_pixel: i32,
	shm_pool: wayland.Wl_Shm_Pool,
	shared_buffer: ^shared.Shared_Buffer,
	buffer: ^wayland.Wl_Buffer,
	seat_name: string,
}

window_context: Window_Context

wl_shm_format_callback :: proc(user_data: rawptr, wl_shm_id: u32, format: wayland.Wl_Shm_Format) {
	append(&window_context.available_formats, format)
}

wl_seat_name_callback :: proc(user_data: rawptr, wl_seat: u32, name: string) {
	fmt.println("seat name: ", name)
	window_context.seat_name, _ = strings.clone(name)
}

wl_seat_capabilities_callback :: proc(user_data: rawptr, wl_seat: u32, capabilities: u32) {
	fmt.printfln("capabilities: %x", capabilities)
}

wl_registry_global_callback :: proc(user_data: rawptr, wl_registry_id: u32, name: u32, interface: string, version: u32) {
	fmt.println(interface)
	if interface == "wl_compositor" {
		window_context.wl_compositor_id = wayland.bind_wl_compsitor_global_object(
			wl_registry_id,
			name,
			interface,
			version
		)
	} else if interface == "wl_shm" {
		window_context.wl_shm_id = wayland.bind_wl_shm_global_object(
			wl_registry_id,
			name,
			interface,
			version
		)
		wayland.wl_shm_set_format_callback(
			window_context.wl_shm_id,
			nil,
			wl_shm_format_callback
		)
	} else if interface == "xdg_wm_base" {
		window_context.xdg_wm_base_id = wayland.bind_xdg_wm_base(
			wl_registry_id,
			name,
			interface,
			version
		)
	} else if interface == "zxdg_decoration_manager_v1" {
		window_context.zxdg_decoration_manager_v1_id = wayland.bind_zxdg_decoration_manager_v1(
			wl_registry_id,
			name,
			interface,
			version
		)
	} else if interface == "wl_seat" {
		window_context.wl_seat_id = wayland.bind_wl_seat(
			wl_registry_id,
			name,
			interface,
			version
		)

		wayland.wl_seat_set_name_callback(
			window_context.wl_seat_id,
			nil,
			wl_seat_name_callback
		)

		wayland.wl_seat_set_capabilities_callback(
			window_context.wl_seat_id,
			nil,
			wl_seat_capabilities_callback
		)
	}
}

init :: proc() -> bool {

	if !wayland.connect() {
		return false
	}

	registry, ok := wayland.wl_display_get_registry()
	if !ok {
		return false
	}

	wayland.wl_registry_set_event_global_callback(registry,  wl_registry_global_callback, nil)

	roundtrip()

	return true
	
}

deinit :: proc() {
	//wayland.zxdg_decoration_manager_v1_destroy(window_context.zxdg_decoration_manager_v1)
	wayland.xdg_toplevel_destroy(window_context.xdg_toplevel_id)
	wayland.xdg_surface_destroy(window_context.xdg_surface_id)
	wayland.xdg_wm_base_destroy(window_context.xdg_wm_base_id)
	wayland.wl_surface_destroy(window_context.wl_surface_id)
	// TODO: destruir os outros objetos globais tambem
	linux.close(wayland.wayland_file_descriptor)
}


roundtrip :: proc() {
	defer free_all(context.temp_allocator)
	should_stop_reading := false
	wl_done_callback :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
		should_stop_reading := transmute(^bool)user_data
		should_stop_reading^ = true
	}
	wayland.wl_display_sync(wl_done_callback, &should_stop_reading)
	for !should_stop_reading {
		msg, _ := wayland.read_message()
		defer delete(msg.arguments)
		id := wayland.get_message_object_id(msg)
		if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
			dispatch(msg)
		}
	}
}

xdg_wm_base_ping_callback :: proc(user_data: rawptr, xdg_wm_base_id: u32, serial: u32) {
	fmt.println("ping")
	wayland.xdg_wm_base_pong(xdg_wm_base_id, serial)
}

xdg_surface_configure_callback :: proc(user_data: rawptr, xdg_surface_id: u32, serial: u32) {
	wayland.wl_surface_attach(
		window_context.wl_surface_id,
		window_context.buffer,
		0,
		0
	)
	
	wayland.xdg_surface_ack_configure(xdg_surface_id, serial)
	wayland.wl_surface_commit(window_context.wl_surface_id)
}

xdg_toplevel_close_callback :: proc(user_data: rawptr, xdg_toplevel_id: u32) {
	window_context.window_should_close = true
}

xdg_toplevel_configure_callback :: proc(user_data: rawptr, xdg_toplevel_id: u32, width: i32, height: i32, states: []wayland.Xdg_Toplevel_State) {
	if width == 0 || height == 0 {
		return
	} 
	
	if int(width * height * window_context.bytes_per_pixel) > len(window_context.shm_pool.shared_buffer.data) {
		wayland.wl_shm_pool_resize(
			&window_context.shm_pool,
			int(width * height * window_context.bytes_per_pixel)
		)
		fmt.println("It resized")
	}
	window_context.width = width
	window_context.height = height
	window_context.stride = window_context.width * window_context.bytes_per_pixel
	window_context.size = window_context.stride * window_context.height					
	
	old_buffer := window_context.buffer
	window_context.buffer, _ = wayland.wl_shm_pool_create_buffer(
		&window_context.shm_pool,
		0,
		window_context.width,
		window_context.height,
		window_context.stride,
		window_context.format
	)
	// isso é uma gambiarra pois os buffers funcionam de um jeito muito estranho
	wayland.wl_buffer_destroy(old_buffer)
	pop_front(&window_context.shm_pool.buffers)
	
}

zxdg_toplevel_decoration_configure_callbak :: proc(user_data: rawptr, zxdg_toplevel_decoration_v1_id: u32, mode: wayland.Zxdg_Toplevel_Decoration_V1_mode) {
	wayland.zxdg_toplevel_decoration_v1_set_mode(
		zxdg_toplevel_decoration_v1_id,
		mode
	)
}

create_window :: proc(width: i32, height: i32, title: string) -> bool {
	window_context.width = width
	window_context.height = height
	window_context.format = .xrgb8888
	window_context.bytes_per_pixel = 4
	window_context.stride = window_context.width * window_context.bytes_per_pixel
	window_context.size = window_context.stride * window_context.height

	ok: bool

	wayland.xdg_wm_base_set_ping_callback(
		window_context.xdg_wm_base_id,
		nil,
		xdg_wm_base_ping_callback
	)

	window_context.shared_buffer, ok = shared.create_shared_buffer(
		"handmade",
		uint(window_context.size)
	)
	if !ok {
		fmt.println("could not create shared buffer")
		return false
	}

	window_context.shm_pool, _ = wayland.wl_shm_create_pool(
		window_context.wl_shm_id,
		window_context.shared_buffer,
		int(window_context.size)
	)

	window_context.buffer, ok = wayland.wl_shm_pool_create_buffer(
		&window_context.shm_pool,
		0,
		window_context.width,
		window_context.height,
		window_context.stride,
		window_context.format
	)
	if !ok {
		fmt.println("could not create buffer")
	}

	window_context.wl_surface_id = wayland.wl_compositor_create_surface(
		window_context.wl_compositor_id
	)

	window_context.xdg_surface_id, ok = wayland.xdg_wm_base_get_xdg_surface(
		window_context.xdg_wm_base_id,
		window_context.wl_surface_id,
	)
	wayland.xdg_surface_set_configure_callback(
		window_context.xdg_surface_id,
		nil,
		xdg_surface_configure_callback
	)

	window_context.xdg_toplevel_id, _ = wayland.xdg_surface_get_toplevel(window_context.xdg_surface_id)
	wayland.xdg_toplevel_set_close_callback(
		window_context.xdg_toplevel_id,
		nil,
		xdg_toplevel_close_callback
	)
	wayland.xdg_toplevel_set_configure_callback(
		window_context.xdg_toplevel_id,
		nil,
		xdg_toplevel_configure_callback
	)
	wayland.xdg_toplevel_set_title(window_context.xdg_toplevel_id, "handmade")

	// If por conta que gnome é uma merda e não implementa ssd.
	if window_context.zxdg_decoration_manager_v1_id != 0 {
		window_context.zxdg_toplevel_decoration_id = wayland.zxdg_decoration_manager_v1_get_toplevel_decoration(
			window_context.zxdg_decoration_manager_v1_id,
			window_context.xdg_toplevel_id
		)
	}
	


	wayland.wl_surface_commit(window_context.wl_surface_id)

	
	
	return true

}

get_window_context :: proc() -> Window_Context {
	return window_context
}

clear_window :: proc() {
	buffer_data := &window_context.buffer.data[0]
	for y in 0..<window_context.height {
		pixel := transmute(^u32)buffer_data
		for x in 0..<window_context.width {
			pixel^ = 0xFFFFFFFF
			pixel = mem.ptr_offset(pixel, 1)
		}
		buffer_data = mem.ptr_offset(buffer_data, window_context.stride)
	}
}

window_should_close :: proc() -> bool {
	return window_context.window_should_close
}

begin_drawing :: proc() {
	wayland.wl_surface_damage_buffer(window_context.wl_surface_id, 0, 0, window_context.width, window_context.height)
	roundtrip()
}

end_drawing :: proc() {
	wayland.wl_surface_attach(
		window_context.wl_surface_id,
		window_context.buffer,
		0,
		0
	)
	wayland.wl_surface_commit(window_context.wl_surface_id)
}
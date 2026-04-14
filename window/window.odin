package window

import "vendor:windows/wasapi"
import "core:os"
import "../wayland"
import "../shared"
import "core:log"
import "core:time"
import "core:fmt"
import "core:strings"

Wayland_Global_Objects :: struct {
	wl_registry_id:   u32,
	wl_compositor_id: u32,
	wl_shm_id:        u32,
	xdg_wm_base_id:   u32,
}

@(private)
wayland_global_objects: Wayland_Global_Objects

@(private)
has_been_initialized: bool = false
@(private)
MAXIMUM_NUBER_OF_FORMAT_PIXELS :: 256

@(private)
suported_formats: [dynamic; MAXIMUM_NUBER_OF_FORMAT_PIXELS]wayland.Wl_Shm_Format


handle_errors :: proc(
	user_data: rawptr,
	wl_display_id: u32,
	error_obj_id: u32,
	error: wayland.Global_Error,
	message: string,
) {
	log.errorf("Erro no objeto(%d): %s\n", error_obj_id, message)
}

handle_format :: proc(user_data: rawptr, wl_shm_id: u32, format: wayland.Wl_Shm_Format) {
	append(&suported_formats, format)
	fmt.println(format)
}

handle_global :: proc(
	user_data: rawptr,
	wl_registry_id: u32,
	name: u32,
	interface: string,
	version: u32,
) {
	if interface == "wl_shm" {
		wayland_global_objects.wl_shm_id = wayland.bind_wl_shm_global_object(
			wl_registry_id,
			name,
			interface,
			version,
		)
		wayland.wl_shm_set_format_callback(
			wayland_global_objects.wl_shm_id,
			nil,
			handle_format,
		)
	} else if interface == "xdg_wm_base" {
		wayland_global_objects.xdg_wm_base_id = wayland.bind_xdg_wm_base(wl_registry_id, name, interface, version)
		handle_ping :: proc(user_data: rawptr, xdg_wm_base_id: u32, serial: u32) {
			wayland.xdg_wm_base_pong(xdg_wm_base_id, serial)
		}
		wayland.xdg_wm_base_set_ping_callback(
			wayland_global_objects.xdg_wm_base_id,
			nil,
			handle_ping
		)
	} else if interface == "wl_compositor" {
		wayland_global_objects.wl_compositor_id = wayland.bind_wl_compsitor_global_object(
			wl_registry_id,
			name,
			interface,
			version,
		)
	}
}


Close_Event :: u32

@(private)
Close_Event_Constant :Close_Event: 0

Event :: union {
	Close_Event,
}

@(private)
events: [dynamic]Event = nil


initialize :: proc() -> bool {
	log.info("Inicializando sistema de criação de janela")

	events = make(type_of(events))

	if wayland.connect() == false {
		log.error("Falha ao conectar no socker do wayland.")
		return false
	}
	wayland.wl_display_set_event_error_callback(handle_errors, nil)

	wayland_global_objects.wl_registry_id, _ = wayland.wl_display_get_registry()
	wayland.wl_registry_set_event_global_callback(
		wayland_global_objects.wl_registry_id,
		handle_global,
		nil,
	)

	has_been_initialized = true

	should_stop_reading := false

	handle_done :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
		should_stop_reading := transmute(^bool)user_data
		should_stop_reading^ = true
	}

	wayland.wl_display_sync(handle_done, &should_stop_reading)

	for !should_stop_reading {
		msg, ok := wayland.read_message()
		defer delete(msg.arguments)
		id := wayland.get_message_object_id(msg)
		if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
			dispatch(msg)
		}
	}

	return true
}


Window_Creation_Flags :: enum {
	fullscreen,
	decoration,
	resizable,
	maximizable,
	minimizable,
}

Window_Creation_Option :: struct {
	title: string,
	width: i32,
	height: i32,
	app_id: string,
	max_width: i32,
	max_height: i32,
	min_width: i32,
	min_height: i32,
	bytes_per_pixel: i32,
	pixel_format: wayland.Wl_Shm_Format,
	flags: bit_set[Window_Creation_Flags]
}


Window_Context :: struct {
	width: i32,
	height: i32,
	bytes_per_pixel: i32,
	pixel_format: wayland.Wl_Shm_Format,
	pool: wayland.Wl_Shm_Pool,
	front_buffer:             ^wayland.Wl_Buffer,
	back_buffer:              ^wayland.Wl_Buffer,
	wl_surface_id:            u32,
	xdg_surface_id:           u32,
	xdg_toplevel_id:          u32,
	has_been_congigured_once: bool,
	resizable:				  bool,
	should_resize:            bool,
}


@(private)
window_context: Window_Context


handle_xdg_surface_configure :: proc(user_data: rawptr, xdg_surface_id: u32, serial: u32) {

	window_context.has_been_congigured_once = true
	wayland.xdg_surface_ack_configure(
		window_context.xdg_surface_id,
		serial
	)
	
	if window_context.has_been_congigured_once {
		wayland.wl_surface_attach(
			window_context.wl_surface_id,
			window_context.front_buffer
		)
		
		wayland.wl_surface_commit(window_context.wl_surface_id)
	}
	
}

handle_xdg_toplevel_configure :: proc(user_data: rawptr, xdg_toplevel_id: u32, width: i32, height: i32, states: []wayland.Xdg_Toplevel_State) {
	// a doc fala que o cliente precisa decidir o tamanho dele nesse caso
	// então só não mexemos em nada
	if width == 0 && height == 0 {
		return
	}
	new_size: i32 = width * height * window_context.bytes_per_pixel
	if new_size < (window_context.width * window_context.height * window_context.bytes_per_pixel) {
		window_context.back_buffer.data = window_context.back_buffer.data[:new_size] 
		window_context.front_buffer.data = window_context.front_buffer.data[:new_size]
		window_context.should_resize = true
	} else if new_size > (window_context.width * window_context.height * window_context.bytes_per_pixel) {
		old_back_buffer := window_context.back_buffer
		old_front_buffer := window_context.front_buffer
		if len(window_context.pool.shared_buffer.data) < int(new_size) {
			wayland.wl_shm_pool_resize(
			&window_context.pool,
			int(new_size)
			)
		}
		
		window_context.back_buffer, _ = wayland.wl_shm_pool_create_buffer(
			&window_context.pool,
			0,
			width,
			height,
			width * window_context.bytes_per_pixel,
			window_context.pixel_format,
			// isso não é um bug eu realmente não quero que seja alocado com o alocador temporário
			context.allocator
		)
		window_context.front_buffer, _ = wayland.wl_shm_pool_create_buffer(
			&window_context.pool,
			new_size,
			width,
			height,
			width * window_context.bytes_per_pixel,
			window_context.pixel_format,
			// isso não é um bug eu realmente não quero que seja alocado com o alocador temporário
			context.allocator
		)
		wayland.wl_buffer_destroy(old_back_buffer)
		wayland.wl_buffer_destroy(old_front_buffer)
		window_context.should_resize = true
	}

	window_context.width = width
	window_context.height = height

}

create_window :: proc(window_creation_options: Window_Creation_Option, allocator := context.temp_allocator) -> bool {
	assert(has_been_initialized, "Before calling create_window should call initialize")
	assert(window_creation_options.width > 0)
	assert(window_creation_options.height > 0)
	assert(window_creation_options.bytes_per_pixel != 0)
	fmt.println("creating window")
	
	window_context.width = window_creation_options.width
	window_context.height = window_creation_options.height
	window_context.bytes_per_pixel = window_creation_options.bytes_per_pixel
	
	shared_buffer_name := window_creation_options.title

	shared_buffer, ok := shared.create_shared_buffer(
		shared_buffer_name, 
		uint((window_creation_options.width * window_creation_options.height * window_creation_options.bytes_per_pixel) * 2)
	)

	if !ok {
		return false
	}

	window_context.pool, _ = wayland.wl_shm_create_pool(
		wayland_global_objects.wl_shm_id, shared_buffer,
		len(shared_buffer.data)
	)

	window_context.back_buffer, ok = wayland.wl_shm_pool_create_buffer(
		&window_context.pool,
		0,
		window_creation_options.width,
		window_creation_options.height,
		window_creation_options.width * window_creation_options.bytes_per_pixel,
		window_creation_options.pixel_format,
		// isso não é um bug eu realmente não quero que seja alocado com o alocador temporário
		context.allocator
	)

	if !ok {
		fmt.println("Could not create back_buffer")
		return false
	}

	window_context.front_buffer, _ = wayland.wl_shm_pool_create_buffer(
		&window_context.pool,
		window_creation_options.width * window_creation_options.height * window_creation_options.bytes_per_pixel,
		window_creation_options.width,
		window_creation_options.height,
		window_creation_options.width * window_creation_options.bytes_per_pixel,
		window_creation_options.pixel_format,
		// isso não é um bug eu realmente não quero que seja alocado com o alocador temporário
		context.allocator
	)

	if !ok {
		fmt.println("Could not create front_buffer")
		return false
	}

	
	window_context.wl_surface_id = wayland.wl_compositor_create_surface(wayland_global_objects.wl_compositor_id)
	
	window_context.xdg_surface_id, _ = wayland.xdg_wm_base_get_xdg_surface(
		wayland_global_objects.xdg_wm_base_id,
		window_context.wl_surface_id
	)	

	wayland.xdg_surface_set_configure_callback(
		window_context.xdg_surface_id,
		nil,
		handle_xdg_surface_configure
	)

	window_context.xdg_toplevel_id, _ = wayland.xdg_surface_get_toplevel(window_context.xdg_surface_id)

	wayland.xdg_toplevel_set_title(window_context.xdg_toplevel_id, window_creation_options.title)
	wayland.xdg_toplevel_set_app_id(window_context.xdg_toplevel_id, window_creation_options.app_id)
	
	if .fullscreen in  window_creation_options.flags {
		wayland.xdg_toplevel_set_fullscreen(window_context.xdg_toplevel_id, nil)
	}

	if .resizable in window_creation_options.flags {
		window_context.resizable = true
	}	
	
	
	wayland.xdg_toplevel_set_configure_callback(
		window_context.xdg_toplevel_id,
		nil,
		handle_xdg_toplevel_configure
	)
	

	handle_close :: proc(user_data: rawptr, xdg_toplevel_id: u32) {
		append(&events, Close_Event_Constant)
	}

	wayland.xdg_toplevel_set_close_callback(
		window_context.xdg_toplevel_id,
		nil,
		handle_close
	)

	wayland.wl_surface_commit(window_context.wl_surface_id)
	

	return true

}

read_all_wayland_events :: proc() {
		should_stop_reading := false

		handle_done :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
			should_stop_reading := transmute(^bool)user_data
			should_stop_reading^ = true
		}

		wayland.wl_display_sync(handle_done, &should_stop_reading)

		for !should_stop_reading {
			msg, ok := wayland.read_message()
			defer delete(msg.arguments)
			id := wayland.get_message_object_id(msg)
			opcode := wayland.get_message_opcode(msg)
			if id == window_context.xdg_toplevel_id && opcode == u16(wayland.Xdg_Toplevel_Events.close){
				fmt.println("close")
			}
			if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
				dispatch(msg)
			}
		}
}

read_event :: proc(e: ^Event) -> bool {
	if len(events) == 0 {
		read_all_wayland_events()
	}

	if event, ok := pop_safe(&events); ok {
		e^ = event
		return true
	}

	return false
}
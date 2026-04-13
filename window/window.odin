package window

import "../wayland"
import "core:log"

Window_Context :: struct {
	front_buffer:             ^wayland.Wl_Buffer,
	back_buffer:              ^wayland.Wl_Buffer,
	wl_surface_id:            u32,
	xdg_surface_id:           u32,
	xdg_toplevel_id:          u32,
	has_been_congigured_once: bool,
}

@(private)
window_context: Window_Context

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
	} else if interface == "wl_compositor" {
		wayland_global_objects.wl_compositor_id = wayland.bind_wl_compsitor_global_object(
			wl_registry_id,
			name,
			interface,
			version,
		)
	}
}

initialize :: proc() -> bool {
	log.info("Inicializando sistema de criação de janela")

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

create_window :: proc(title: string, width: i32, height: i32, app_id := title) -> bool {
	assert(has_been_initialized, "Before calling create_window should call initialize")
	
}
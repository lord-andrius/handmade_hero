package main

import "core:fmt"
import "wayland"
import "shared"

wl_shm_id: u32 = 0

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
		
	}
}

handle_done_sync_callback :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
	deve_sair := transmute(^bool)user_data
	fmt.println("done")
	deve_sair^ = true
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

	WIDTH :: 1440
	HEIGHT :: 900
	BYTES_PER_PIXEL :: 4

	buffer, ok := shared.create_shared_buffer("handmade", (WIDTH * HEIGHT * BYTES_PER_PIXEL) * 2)
	assert(ok)
	defer shared.destroy_shared_buffer(buffer)

	wayland.wl_shm_create_pool(wl_shm_id, buffer, len(buffer.data))

	deve_sair = false

	wayland.wl_display_sync(handle_done_sync_callback, &deve_sair)

	for !deve_sair {
		msg, ok := wayland.read_message()
		defer delete(msg.arguments)
		id := wayland.get_message_object_id(msg)
		if dispatch, ok := wayland.id_context.object_id_to_interface_displatch_proc[id]; ok {
			dispatch(msg)
		}
	}
}

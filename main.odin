package main

import "core:fmt"
import "wayland"

error_callback :: proc(user_data: rawptr, wl_display_id: u32, error_obj_id: u32, error: wayland.Global_Error, message: string) {
	fmt.printfln("%v %s", error, message)
}

handle_global_callback :: proc(user_data: rawptr, wl_registry_id: u32, name: u32, interface: string, version: u32) {
	fmt.printfln("name: %d | interface: %s | version: %d", name, interface, version)
}

handle_done_sync_callback :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32) {
	deve_sair := transmute(^bool)user_data
	deve_sair^ = true
}

main :: proc() {
	wayland.connect()
	wayland.wl_display_set_event_error_callback(error_callback, nil)

	registry, _ := wayland.wl_display_get_registry()

	wayland.wl_registry_set_event_global_callback(registry, handle_global_callback, nil)
	wayland.wl_registry_set_event_global_callback(registry, handle_global_callback, nil)


	deve_sair := false
	wayland.wl_display_sync(handle_done_sync_callback, &deve_sair)

	for !deve_sair {
		msg, ok := wayland.read_message()
		defer delete(msg.arguments)
		wayland.wl_display_dispath(msg)
		wayland.wl_registry_dispatch(msg)
		wayland.wl_callback_dispatch(msg)
	}
	
}

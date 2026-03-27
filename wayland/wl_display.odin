package wayland

import "core:sys/linux"

WL_DISPLAY_OBJECT_ID :: 1

// requests
Wl_Display_Requests :: enum(u32) {
    sync,
    get_registry,
}

// events
Wl_Display_Events :: enum(u32) {
    error,
    delete_id,   
}

Wl_Display_Events_Callbacks: [Wl_Display_Events]struct {
    callback: rawptr,
    user_data: rawptr
}

Global_Error :: enum(u32) {
    invalid_object,

}

wl_display_set_event_error_callback :: proc(callback: proc(user_data: rawptr, wl_display_id: u32, error_obj_id: u32, erro: Global_Error, message: string), user_data: rawptr) {
    Wl_Display_Events_Callbacks[.error].callback = transmute(rawptr)callback
    Wl_Display_Events_Callbacks[.error].user_data = user_data
}

wl_display_set_event_delete_id_callback :: proc(callback: proc(user_data: rawptr, wl_display_id: u32, deleted_object_id: u32), user_data: rawptr) {
    Wl_Display_Events_Callbacks[.delete_id].callback = transmute(rawptr)callback
    Wl_Display_Events_Callbacks[.error].user_data = user_data
}

wl_display_sync :: proc(fd: linux.Fd, new_callback_id: u32, done_callback: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32)) -> bool {
 WL_DISPLAY_SYNC_OPCODE :: 1
 id := generate_new_id(wl_done_dispatch)
 msg: Message
 set_message_object(&msg, WL_DISPLAY_OBJECT_ID)
 set_message_opcode(&msg, WL_DISPLAY_SYNC_OPCODE)
 args_buf: [4]u8
 msg.arguments = args_buf[:]
 write_uint_into_message_args(msg, id)
 set_message_length_based_on_args_length(&msg)
 _, ok := write_message(fd, msg)
 return ok
}


wl_display_dispath :: proc(message: Message) {

}
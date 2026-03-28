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
    invalid_method,
    no_memory,
    implementation,
}

Wl_Display_Event_Error_Callback :: proc(user_data: rawptr, wl_display_id: u32, error_obj_id: u32, error: Global_Error, message: string)
wl_display_set_event_error_callback :: proc(callback: Wl_Display_Event_Error_Callback, user_data: rawptr) {
    Wl_Display_Events_Callbacks[.error].callback = transmute(rawptr)callback
    Wl_Display_Events_Callbacks[.error].user_data = user_data
}

Wl_Display_Event_Delete_Id_Callback :: proc(user_data: rawptr, wl_display_id: u32, deleted_object_id: u32)
wl_display_set_event_delete_id_callback :: proc(callback: Wl_Display_Event_Delete_Id_Callback, user_data: rawptr) {
    Wl_Display_Events_Callbacks[.delete_id].callback = transmute(rawptr)callback
    Wl_Display_Events_Callbacks[.error].user_data = user_data
}


// retorno o id da callback
wl_display_sync :: proc(done_callback: Wl_Callback_Event_Done_Callback, user_data: rawptr) -> (u32, bool) {
 fd := wayland_file_descriptor
 id := generate_new_id(wl_callback_dispatch)
 wl_callback_set_done_callback(id, user_data, done_callback)
 msg: Message
 set_message_object(&msg, WL_DISPLAY_OBJECT_ID)
 set_message_opcode(&msg, u16(Wl_Display_Requests.sync))
 args_buf: [4]u8
 msg.arguments = args_buf[:]
 write_uint_into_message_args(msg, id)
 set_message_length_based_on_args_length(&msg)
 _, ok := write_message(msg)
 return id, ok
}

wl_display_get_registry :: proc() -> (u32, bool) {
    fd := wayland_file_descriptor
    id := generate_new_id(wl_registry_dispatch)
    msg: Message
    set_message_object(&msg, WL_DISPLAY_OBJECT_ID)
    set_message_opcode(&msg, u16(Wl_Display_Requests.get_registry))
    args_buf: [4]u8
    msg.arguments = args_buf[:]
    write_uint_into_message_args(msg, id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return id, ok
}


wl_display_dispath :: proc(message: Message) {
 object_id := get_message_object_id(message)
 if object_id != WL_DISPLAY_OBJECT_ID {
    return
 }
 event := Wl_Display_Events(get_message_opcode(message))
 length := get_message_length(message)

 switch event {
    case .error:
        if Wl_Display_Events_Callbacks[.error].callback == nil {
            return
        }
        callback :=  Wl_Display_Event_Error_Callback(Wl_Display_Events_Callbacks[.error].callback)
        index_on_arguments: int
        tmp: u32
        error_obj_id: u32
        error: Global_Error
        message_error_description: string
        
        error_obj_id, index_on_arguments = read_uint_from_message_args(message)
        // NOTA: criar uma função genêrica que leia dos argumentos de acordo com o tamanho do tipo concreto.
        tmp, index_on_arguments = read_uint_from_message_args(message, index_on_arguments)
        error = Global_Error(tmp)
        message_error_description, index_on_arguments = read_string_from_message_args(message, index_on_arguments)
        callback(Wl_Display_Events_Callbacks[.error].user_data, WL_DISPLAY_OBJECT_ID, error_obj_id, error, message_error_description)
        

    case .delete_id:
        if Wl_Display_Events_Callbacks[.delete_id].callback == nil {
            return
        }
        callback := Wl_Display_Event_Delete_Id_Callback(Wl_Display_Events_Callbacks[.delete_id].callback)
        deleted_id, _ := read_uint_from_message_args(message)
        callback(Wl_Display_Events_Callbacks[.delete_id].user_data, WL_DISPLAY_OBJECT_ID, deleted_id)
 }
}
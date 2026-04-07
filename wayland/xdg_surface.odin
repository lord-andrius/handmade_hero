package wayland

Xdg_Surface_Error :: enum(u32) {
    not_constructed,
    alredy_constructed,
    unconfigured_buffer,
    invalid_serial,
    invalid_size,
    defunct_role_object,
}

Xdg_Surface_Request :: enum(u32) {
    destroy,
    get_top_level,
    get_popup,
    set_window_geometry,
    ack_configure,
}

Xdg_Surface_Events :: enum(u32) {
    configure,
}

Xdg_Surface_Event_Configure_Callback :: proc(user_data: rawptr, xdg_surface_id: u32, serial: u32)

Xdg_Surface_Events_Callbacks :: map[u32]struct {
    callback: Xdg_Surface_Event_Configure_Callback,
    user_data: rawptr,
}

xdg_surface_events_callbacks: Xdg_Surface_Events_Callbacks = nil

xdg_surface_destroy :: proc(xdg_surface_id: u32)  -> bool{
    delete_key(&xdg_surface_events_callbacks, xdg_surface_id)
    delete_id(xdg_surface_id)
    msg: Message
    set_message_object(&msg, xdg_surface_id)
    set_message_opcode(&msg, u16(Xdg_Surface_Request.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_surface_get_toplevel :: proc(xdg_surface_id: u32) -> (u32, bool) {
    new_toplevel_id := generate_new_id(xdg_toplevel_dispatch)
    msg: Message
    args_buf: [size_of(u32)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_surface_id)
    set_message_opcode(&msg, u16(Xdg_Surface_Request.get_top_level))
    write_uint_into_message_args(msg, new_toplevel_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return new_toplevel_id, ok
}

xdg_surface_get_popup :: proc(xdg_surface_id: u32) -> (u32, bool) {
    new_popup_id := generate_new_id(xdg_popup_dispatch)
    msg: Message
    args_buf: [size_of(u32)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_surface_id)
    set_message_opcode(&msg, u16(Xdg_Surface_Request.get_popup))
    write_uint_into_message_args(msg, new_popup_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return new_popup_id, ok
}

xdg_surface_set_window_geometry :: proc(xdg_surface_id: u32, x: i32, y: i32, width: i32, height: i32) -> bool {
    msg: Message
    args_buf: [size_of(i32) * 4]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_surface_id)
    set_message_opcode(&msg, u16(Xdg_Surface_Request.set_window_geometry))
    args_index := write_int_into_message_args(msg, x)
    args_index = write_int_into_message_args(msg, y, args_index)
    args_index = write_int_into_message_args(msg, width, args_index)
    args_index = write_int_into_message_args(msg, height, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_surface_ack_configure :: proc(xdg_surface_id: u32, serial: u32) -> bool{
    msg: Message
    args_buf: [size_of(i32)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_surface_id)
    set_message_opcode(&msg, u16(Xdg_Surface_Request.ack_configure))
    write_uint_into_message_args(msg, serial)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_surface_set_configure_callback :: proc(xdg_surface_id: u32, user_data: rawptr, callback: Xdg_Surface_Event_Configure_Callback) {
    if xdg_surface_events_callbacks == nil {
        xdg_surface_events_callbacks = make(type_of(xdg_surface_events_callbacks))
    }

    xdg_surface_events_callbacks[xdg_surface_id] = {
        callback = callback,
        user_data = user_data,
    }
}



xdg_surface_dispatch :: proc(msg: Message) {
    xdg_surface_id := get_message_object_id(msg)
    // não tem necessidade de checar o opcode pq só tem um evento
    callback, ok := xdg_surface_events_callbacks[xdg_surface_id]
    if !ok || callback.callback == nil {
        return
    }
    serial, _ := read_uint_from_message_args(msg)
    callback.callback(callback.user_data, xdg_surface_id, serial)
}
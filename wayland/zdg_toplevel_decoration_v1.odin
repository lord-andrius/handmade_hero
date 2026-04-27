package wayland

Zxdg_Toplevel_Decoration_V1_Requests :: enum(u32) {
    destroy,
    set_mode,
    unset_mode,
}

Zxdg_Toplevel_Decoration_V1_Events :: enum(u32) {
    configure,   
}

Zxdg_Toplevel_Decoration_V1_Configure_Callback :: proc(user_data: rawptr, zxdg_toplevel_decoration_v1_id: u32, mode: Zxdg_Toplevel_Decoration_V1_mode)

Zxdg_Toplevel_Decoration_V1_mode :: enum(u32) {
    client_side = 1,
    server_side,
}

Zxdg_Toplevel_Decoration_V1_Callbacks :: map[u32]struct {
    callback: Zxdg_Toplevel_Decoration_V1_Configure_Callback,
    user_data: rawptr,
}

zxdg_toplevel_decoration_v1_callbacks: Zxdg_Toplevel_Decoration_V1_Callbacks = nil

zxdg_toplevel_decoration_v1_destroy :: proc(zxdg_toplevel_decoration_v1_id: u32) -> bool {
    delete_id(zxdg_toplevel_decoration_v1_id)
    msg: Message
    set_message_object(&msg, zxdg_toplevel_decoration_v1_id)
    set_message_opcode(&msg, u16(Zxdg_Toplevel_Decoration_V1_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

zxdg_toplevel_decoration_v1_set_mode :: proc(zxdg_toplevel_decoration_v1_id: u32, mode: Zxdg_Toplevel_Decoration_V1_mode) -> bool {
    msg: Message
    arg_buf: [size_of(mode)]u8
    msg.arguments = arg_buf[:]
    set_message_object(&msg, zxdg_toplevel_decoration_v1_id)
    set_message_opcode(&msg, u16(Zxdg_Toplevel_Decoration_V1_Requests.set_mode))
    write_uint_into_message_args(msg, u32(mode))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

zxdg_toplevel_decoration_v1_unset_mode :: proc(zxdg_toplevel_decoration_v1_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, zxdg_toplevel_decoration_v1_id)
    set_message_opcode(&msg, u16(Zxdg_Toplevel_Decoration_V1_Requests.unset_mode))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

zxdg_toplevel_decoration_v1_set_configure :: proc(zxdg_toplevel_decoration_v1_id: u32, user_data: rawptr, callback: Zxdg_Toplevel_Decoration_V1_Configure_Callback) {
    if zxdg_toplevel_decoration_v1_callbacks == nil {
        zxdg_toplevel_decoration_v1_callbacks = make(type_of(zxdg_toplevel_decoration_v1_callbacks))
    }

    zxdg_toplevel_decoration_v1_callbacks[zxdg_toplevel_decoration_v1_id] = {
        callback = callback,
        user_data = user_data
    }
}

zxdg_toplevel_decoration_v1_dispatch :: proc(msg: Message) {
    if zxdg_toplevel_decoration_v1_callbacks == nil do return
    zxdg_toplevel_decoration_v1_id := get_message_object_id(msg)
    mode, _ := read_uint_from_message_args(msg)
    if callback, ok := zxdg_toplevel_decoration_v1_callbacks[zxdg_toplevel_decoration_v1_id]; ok {
        callback.callback(callback.user_data, zxdg_toplevel_decoration_v1_id, Zxdg_Toplevel_Decoration_V1_mode(mode))
    }
}
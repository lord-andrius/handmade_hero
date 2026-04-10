package wayland

import "core:fmt"

Xdg_Wm_Base_Errors :: enum(u32) {
    role,
    defunc_surfaces,
    not_the_topmost_popup,
    invalid_popup_parent,
    invalid_surface_state,
    invalid_positioner,
    unresponsive,
}

Xdg_Wm_Base_Requests :: enum(u32) {
    destroy,
    create_positioner,
    get_xdg_surface, 
    pong,
}

Xdg_Wm_Base_Events :: enum(u32) {
    ping,
}

Xdg_Wm_Base_Ping_Event_Callback :: proc(user_data: rawptr, xdg_wm_base_id: u32, serial: u32)

Xdg_Wm_Base_Events_Callbacks :: map[u32]struct {
    callback: Xdg_Wm_Base_Ping_Event_Callback,
    user_data: rawptr
}

xdg_wm_base_events_callbacks: Xdg_Wm_Base_Events_Callbacks = nil

bind_xdg_wm_base :: proc(wl_registry_id: u32, xdg_wm_base_name: u32, interface: string, version: u32) -> u32 {
    id := generate_new_id(xdg_wm_base_dispatch)
    wl_registry_bind(wl_registry_id, xdg_wm_base_name, interface, version, id)
    return id
}

xdg_wm_base_destroy :: proc(xdg_wm_base_id: u32) -> bool {
    delete_key(&xdg_wm_base_events_callbacks, xdg_wm_base_id)
    delete_id(xdg_wm_base_id)
    msg: Message
    set_message_object(&msg, xdg_wm_base_id)
    set_message_opcode(&msg, u16(Xdg_Wm_Base_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}


xdg_wm_base_get_xdg_surface :: proc(xdg_wm_base_id: u32, wl_surface_id: u32) -> (u32, bool) {
    new_xdg_surface_id := generate_new_id(xdg_surface_dispatch)
    msg: Message
    args_buf: [size_of(u32) * 2]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_wm_base_id)
    set_message_opcode(&msg, u16(Xdg_Wm_Base_Requests.get_xdg_surface))
    arg_index := write_uint_into_message_args(msg, new_xdg_surface_id)
    arg_index = write_uint_into_message_args(msg, wl_surface_id, arg_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return new_xdg_surface_id, ok
}

xdg_wm_base_pong :: proc(xdg_wm_base_id: u32, serial: u32) -> bool {
    msg: Message
    args_buf: [size_of(u32)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_wm_base_id)
    set_message_opcode(&msg, u16(Xdg_Wm_Base_Requests.pong))
    _ = write_uint_into_message_args(msg, serial)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    fmt.println("pong")
    return ok
}

xdg_wm_base_set_ping_callback :: proc(xdg_wm_base_id: u32, user_data: rawptr, callback: Xdg_Wm_Base_Ping_Event_Callback) {
    if xdg_wm_base_events_callbacks == nil {
        xdg_wm_base_events_callbacks = make(Xdg_Wm_Base_Events_Callbacks)
    }

    xdg_wm_base_events_callbacks[xdg_wm_base_id] = {
        callback = callback,
        user_data = user_data,
    }
}

xdg_wm_base_dispatch :: proc(msg: Message) {
    //temporario
    xdg_wm_base_id := get_message_object_id(msg)
    callback, ok := xdg_wm_base_events_callbacks[xdg_wm_base_id]
    serial, _ := read_uint_from_message_args(msg)
    // só tem um evento então dá certo não checar por eventos
    if ok {
        callback.callback(callback.user_data, xdg_wm_base_id, serial)
    } else {
        xdg_wm_base_pong(xdg_wm_base_id, serial)
        fmt.println("ping")    
    }
}
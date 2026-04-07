package wayland

Xdg_Toplevel_Requests :: enum(u32) {
    destroy,
    set_parent,
    set_title,
    set_app_id,
    show_window_menu,
    move,
    resize,
    set_max_size,
    set_min_size,
    set_maximazed,
    unset_maximazed,
    set_fullscreen,
    unset_fullscreen,
    set_minimized,
}

Xdg_Toplevel_Events :: enum(u32) {
    configure,
    close,
    configure_bounds,
    wm_capabilities,
}

Xdg_Toplevel_Event_Configure_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32, serial: u32)
Xdg_Toplevel_Close_Configure_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32)


xdg_toplevel_destroy :: proc(xdg_toplevel_id: u32) -> bool{
    delete_id(xdg_toplevel_id)
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_dispatch :: proc(msg: Message) {}
package wayland

bind_wl_compsitor_global_object :: proc(wl_registry_id: u32, wl_compositor_name: u32, interface: string, version: u32) -> u32 {
    id := generate_new_id(nil)
    wl_registry_bind(wl_registry_id, wl_compositor_name, interface, version, id)
    return id
}

Wl_Compositor_Requests :: enum(u32) {
    create_surface,
    create_region,
}

wl_compositor_create_surface :: proc(wl_compositor_id: u32) -> u32 {
    id := generate_new_id(wl_surface_dispatch)
    msg: Message
    arg_buf: [size_of(u32)]u8
    msg.arguments = arg_buf[:]
    set_message_object(&msg, wl_compositor_id)
    set_message_opcode(&msg, u16(Wl_Compositor_Requests.create_surface))
    write_uint_into_message_args(msg, id)
    set_message_length_based_on_args_length(&msg)
    write_message(msg)
    return id
}


wl_compositor_create_region :: proc(wl_compositor_id: u32) -> u32 {
    id := generate_new_id(wl_surface_dispatch)
    msg: Message
    set_message_object(&msg, wl_compositor_id)
    set_message_opcode(&msg, u16(Wl_Compositor_Requests.create_region))
    write_uint_into_message_args(msg, id)
    set_message_length_based_on_args_length(&msg)
    write_message(msg)
    return id
}
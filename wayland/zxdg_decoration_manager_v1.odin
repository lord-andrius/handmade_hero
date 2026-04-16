package wayland

Zxdg_Decoration_Manager_V1_Requests :: enum(u32) {
    destroy,
    get_toplevel_decoration,
}

bind_zxdg_decoration_manager_v1 :: proc(wl_registry_id: u32, name: u32, interface: string, version: u32) -> u32{
    id := generate_new_id(nil)
    wl_registry_bind(
        wl_registry_id,
        name,
        interface,
        version,
        id
    )
    return id
}

zxdg_decoration_manager_v1_destroy :: proc(zxdg_decoration_manager_v1_id: u32) -> bool {
    delete_id(zxdg_decoration_manager_v1_id)
    msg: Message
    set_message_object(&msg, zxdg_decoration_manager_v1_id)
    set_message_opcode(&msg, u16(Zxdg_Decoration_Manager_V1_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

zxdg_decoration_manager_v1_get_toplevel_decoration :: proc(zxdg_decoration_manager_v1_id: u32, xdg_toplevel_id: u32) -> u32 {
    toplevel_decoration_id := generate_new_id(zxdg_toplevel_decoration_v1_dispatch)
    msg: Message
    arg_buf: [size_of(toplevel_decoration_id) + size_of(xdg_toplevel_id)]u8
    msg.arguments = arg_buf[:]
    set_message_object(&msg, zxdg_decoration_manager_v1_id)
    set_message_opcode(&msg, u16(Zxdg_Decoration_Manager_V1_Requests.get_toplevel_decoration))
    arg_index := write_uint_into_message_args(msg, toplevel_decoration_id)
    arg_index = write_uint_into_message_args(msg, xdg_toplevel_id, arg_index)
    set_message_length_based_on_args_length(&msg)
    write_message(msg)
    return toplevel_decoration_id    
}


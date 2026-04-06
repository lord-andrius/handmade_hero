package wayland

Wl_Surface_Error :: enum(u32) {
    invalid_scale,
    invalid_transform,
    invalid_size,
    invalid_offset,
    defunct_role_object,
}

Wl_Surface_Requests :: enum(u32) {
    destroy,
    attach,
    damage,
    frame,
    set_opaque_region,
    set_input_region,
    commit,
    set_buffer_transform,
    set_buffer_scale,
    damage_buffer,
    offset,

}

Wl_Surface_Events :: enum(u32) {
    enter,
    leave,
    preferred_buffer_scale,
    preferred_buffer_transform,

}

wl_surface_destroy :: proc(wl_surface_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

wl_surface_attach :: proc(wl_surface_id: u32, buffer: ^Wl_Buffer, x: i32 = 0, y: i32 = 0) -> bool {
    assert(x != 0 && y != 0, "Use wl_surface_offset for when specifiyng offset")
    msg: Message
    args_buf: [size_of(u32) * 3]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.attach))
    buffer_id := 0 if buffer == nil else buffer.id
    args_index := write_uint_into_message_args(msg, buffer_id)
    args_index = write_int_into_message_args(msg, x, args_index)
    args_index = write_int_into_message_args(msg, y, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

// tá aqui só pra preencher tabela
wl_surface_damage :: proc(wl_surface_id: u32) {
    assert(false, "use wl_surface_damage_buffer insted of wl_surface_damage")
}

wl_surface_frame :: proc(wl_surface_id: u32, callback: Wl_Callback_Event_Done_Callback, user_data: rawptr) -> bool {
    new_callback_id := generate_new_id(wl_callback_dispatch)
    msg: Message
    args_buffer: [size_of(u32)]u8
    msg.arguments = args_buffer[:]
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.frame))
    write_uint_into_message_args(msg, new_callback_id)
    set_message_length_based_on_args_length(&msg)
    wl_callback_set_done_callback(new_callback_id, user_data, callback)
    _, ok := write_message(msg)
    return ok
}
// Isso é uma otimização pro compositor saber que não precisa mostrar
// nada debaixo dessa superfície. Note que o efeito só é aplicado no
// próximo wl_surface_commit.
wl_surface_set_opaque_region :: proc(wl_surface_id: u32, region_id: ^u32) -> bool {
    final_region_id := 0 if region_id == nil else region_id^
    msg: Message
    args_buffer: [size_of(u32)]u8
    msg.arguments = args_buffer[:]
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.set_opaque_region))
    write_uint_into_message_args(msg, final_region_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

// Isso avisa pro compositor que região da surperfície recebe entradas.
// caso a região seja nula toda a superficie recebera entradas. Note que
// só é aplicado depois do próximo wl_surface_commit
wl_surface_set_input_region :: proc(wl_surface_id: u32, region_id: ^u32) -> bool {
    final_region_id := 0 if region_id == nil else region_id^
    msg: Message
    args_buffer: [size_of(u32)]u8
    msg.arguments = args_buffer[:]
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.set_input_region))
    write_uint_into_message_args(msg, final_region_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

wl_surface_commit :: proc(wl_surface_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, wl_surface_id)
    set_message_opcode(&msg, u16(Wl_Surface_Requests.commit))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

wl_surface_dispatch :: proc(msg: Message) {
    
}
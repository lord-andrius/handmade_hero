package wayland

next_available_id: u32 = 256

NEXT_AVAILABLE_ID_LIMIT :: 0xFEFFFFFF

Id_Context :: struct {
    object_id_to_interface_displatch_proc: map[u32]proc(message: Message),
    // deve se usado como uma stack para reaproveitar ids.
    reuse_object_id_poll: [dynamic]u32
    
}

id_context: Id_Context

initialize_ids :: proc() {
    id_context.object_id_to_interface_displatch_proc = make(map[u32]proc(message: Message))
    id_context.object_id_to_interface_displatch_proc[WL_DISPLAY_OBJECT_ID] = wl_display_dispath
    id_context.reuse_object_id_poll = make([dynamic]u32)
}

generate_new_id :: proc(new_id_dispatch_proc: proc(message: Message)) -> u32 {
    new_id: u32
    if len(id_context.reuse_object_id_poll) > 0 {
     new_id = pop(&id_context.reuse_object_id_poll)   
    } else {
        new_id = next_available_id
        next_available_id += 1
        assert(next_available_id <= NEXT_AVAILABLE_ID_LIMIT)
    }

    assert(!(new_id in id_context.object_id_to_interface_displatch_proc))
    id_context.object_id_to_interface_displatch_proc[new_id] = new_id_dispatch_proc
    return new_id
}

delete_id :: proc(id: u32) {
    assert(id in id_context.object_id_to_interface_displatch_proc)
    delete_key(&id_context.object_id_to_interface_displatch_proc, id)
    append(&id_context.reuse_object_id_poll, id)
}
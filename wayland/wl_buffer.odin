package wayland

import "../shared"
import "base:runtime"

Wl_Buffer :: struct {
    shared_buffer: ^shared.Shared_Buffer,
    data: []u8,
    id: u32,
}

@(private)
wl_buffer_id_object_map: map[u32]^Wl_Buffer = nil


Wl_Buffer_Requests :: enum(u32) {
    destroy,
}

Wl_Buffer_Events :: enum(u32) {
    release
}

Wl_Buffer_Event_Release_Callback :: proc(wl_buffer: ^Wl_Buffer)

@(private)
wl_buffer_events_callbacks: map[u32]Wl_Buffer_Event_Release_Callback = nil

wl_buffer_set_release_callback :: proc(wl_buffer: ^Wl_Buffer, callback: Wl_Buffer_Event_Release_Callback) {
    if wl_buffer_events_callbacks == nil {
        wl_buffer_events_callbacks = make(type_of(wl_buffer_events_callbacks))
    }
    wl_buffer_events_callbacks[wl_buffer.id] = callback
}

// Isso é um helper para ajudar a manter o registro dos wl_buffers
@(private)
wl_buffer_create :: proc(id: u32, shared_buffer: ^shared.Shared_Buffer, data: []u8, allocator: runtime.Allocator = context.allocator) -> ^Wl_Buffer {
    buffer := new(Wl_Buffer, allocator)
    buffer.id = id
    buffer.shared_buffer = shared_buffer
    buffer.data = data
    if wl_buffer_id_object_map == nil {
        wl_buffer_id_object_map = make(type_of(wl_buffer_id_object_map))
    }
    wl_buffer_id_object_map[buffer.id] = buffer
    shared.add_one_user_to_shared_buffer(shared_buffer)
    return buffer
}

wl_buffer_destroy :: proc(wl_buffer: ^Wl_Buffer) -> bool {
    msg: Message
    set_message_object(&msg, wl_buffer.id)
    set_message_opcode(&msg, u16(Wl_Buffer_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    if !ok {
        return false
    }
    delete_id(wl_buffer.id)
    shared.destroy_shared_buffer(wl_buffer.shared_buffer)
    free(wl_buffer)
    return ok
}

wl_buffer_dispatch :: proc(msg: Message) {
    id := get_message_object_id(msg)
    event := Wl_Buffer_Events(get_message_opcode(msg))
    callback, ok := wl_buffer_events_callbacks[id]
    if !ok {
        return
    }
    buffer := wl_buffer_id_object_map[id]
    switch event {
        case .release:
            callback(buffer)
    }
}
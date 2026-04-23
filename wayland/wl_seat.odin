package wayland

import "core:fmt"

Wl_Seat_Requests :: enum(u32) {
    get_pointer,
    get_keyboard,
    get_touch,
    release,
}

Wl_Seat_Events :: enum(u32) {
    capabilities,
    name,
}

Wl_Seat_Capabilities_Event_Callback :: proc(user_data: rawptr, wl_seat: u32, capabilities: u32)
Wl_Seat_Name_Event_Callback :: proc(user_data: rawptr, wl_seat: u32, name: string)

Wl_Seat_Events_Callbacks :: map[u32]struct {
    callbacks: [Wl_Seat_Events]rawptr,
    user_data: [Wl_Seat_Events]rawptr,
}

@(private)
wl_seat_events_callbacks: Wl_Seat_Events_Callbacks = nil

Wl_Seat_Capabilities :: enum(u32) {
    pointer = 1,
    keyboard = 2,
    touch = 4
}

bind_wl_seat :: proc(wl_registry_id: u32, wl_compositor_name: u32, interface: string, version: u32) -> u32 {
    id := generate_new_id(wl_seat_dispatch)
    wl_registry_bind(wl_registry_id, wl_compositor_name, interface, version, id)
    return id
}

wl_seat_get_pointer :: proc(wl_seat_id: u32) -> u32 {
    id := generate_new_id(wl_pointer_dispatch)
    msg: Message
    args_buf: [size_of(id)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, wl_seat_id)
    set_message_opcode(&msg, u16(Wl_Seat_Requests.get_pointer))
    write_uint_into_message_args(msg, id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return id
}

wl_seat_get_keyboard :: proc(wl_seat_id: u32) -> u32 {
    id := generate_new_id(wl_keyboard_dispatch)
    msg: Message
    args_buf: [size_of(id)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, wl_seat_id)
    set_message_opcode(&msg, u16(Wl_Seat_Requests.get_keyboard))
    write_uint_into_message_args(msg, id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return id
}

wl_seat_get_touch :: proc(wl_seat_id: u32) -> u32 {
    panic("TODO(Andrew Dylan): Não implementado.")
}

wl_seat_release :: proc(wl_seat_id: u32) {
    delete_id(wl_seat_id)
    msg: Message
    set_message_object(&msg, wl_seat_id)
    set_message_opcode(&msg, u16(Wl_Seat_Requests.release))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
}

wl_seat_set_capabilities_callback :: proc(wl_seat_id: u32, user_data: rawptr, procedure: Wl_Seat_Capabilities_Event_Callback) {
    if wl_seat_events_callbacks == nil {
        wl_seat_events_callbacks = make(type_of(wl_seat_events_callbacks))
    }

    if callback, ok := &wl_seat_events_callbacks[wl_seat_id]; ok {
        callback.callbacks[Wl_Seat_Events.capabilities] = rawptr(procedure)
        callback.user_data[Wl_Seat_Events.capabilities] = user_data
        return
    }

    wl_seat_events_callbacks[wl_seat_id] = {
        callbacks = {.capabilities = rawptr(procedure), .name = nil},
        user_data = {.capabilities = user_data, .name = nil},
    }

}

wl_seat_set_name_callback :: proc(wl_seat_id: u32, user_data: rawptr, procedure: Wl_Seat_Name_Event_Callback) {
    if wl_seat_events_callbacks == nil {
        wl_seat_events_callbacks = make(type_of(wl_seat_events_callbacks))
    }

    if callback, ok := &wl_seat_events_callbacks[wl_seat_id]; ok {
        callback.callbacks[Wl_Seat_Events.name] = rawptr(procedure)
        callback.user_data[Wl_Seat_Events.name] = user_data   
        return
    }

    wl_seat_events_callbacks[wl_seat_id] = {
        callbacks = {.capabilities = nil, .name = rawptr(procedure)},
        user_data = {.capabilities = nil, .name = user_data},
    }
    
}

wl_seat_dispatch :: proc(msg: Message) {
    wl_seat_id := get_message_object_id(msg)
    callback, ok := wl_seat_events_callbacks[wl_seat_id]
    if !ok do return
    event := Wl_Seat_Events(get_message_opcode(msg))
    switch event {
        case .capabilities:
            if callback.callbacks[.capabilities] == nil do return 
            capabilities, _ := read_uint_from_message_args(msg)
            Wl_Seat_Capabilities_Event_Callback(callback.callbacks[.capabilities])(callback.user_data[.capabilities], wl_seat_id, capabilities)
        case .name:
            if callback.callbacks[.name] == nil do return 
            name, _ := read_string_from_message_args(msg)
            Wl_Seat_Name_Event_Callback(callback.callbacks[.name])(callback.user_data[.name], wl_seat_id, name)
    }
}
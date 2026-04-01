package wayland

import "core:fmt"

Wl_Registry_Requests :: enum(u32) {
    bind,
}

Wl_Resgistry_Events :: enum(u32) {
    global,
    global_remove,
}

wl_registry_bind :: proc(wl_registry_id: u32, name: u32, interface: string,version: u32, id: u32) -> bool {
    /*
    msg: Message
    msg_args_buf: [8]u8
    msg.arguments = msg_args_buf[:]
    set_message_object(&msg, wl_registry_id)
    set_message_opcode(&msg, u16(Wl_Registry_Requests.bind))
    index_args := 0
    index_args = write_uint_into_message_args(msg, name)
    write_uint_into_message_args(msg, id, index_args)
    set_message_length_based_on_args_length(&msg)
    bytes_escritos, ok := write_message(msg)
    
    return ok
    */
    
    msg: Message
    arg_buf_len := size_of(name) + size_of(u32) + len(interface) + 1
    if arg_buf_len % 4 != 0 {
        arg_buf_len += 4 - (arg_buf_len % 4)
    }
    arg_buf_len += size_of(version)
    arg_buf_len += size_of(id)
    arg_buf := make([]u8, arg_buf_len)
    defer delete(arg_buf)
    msg.arguments = arg_buf
    set_message_object(&msg, wl_registry_id)
    set_message_opcode(&msg, u16(Wl_Registry_Requests.bind))
    index_args := write_uint_into_message_args(msg, name)
    index_args = write_string_into_message_args(msg, interface, index_args)
    index_args = write_uint_into_message_args(msg, version, index_args)
    index_args = write_uint_into_message_args(msg, id, index_args)
    set_message_length_based_on_args_length(&msg)
    msg_len := get_message_length(msg)
    bytes_lidos, ok := write_message(msg)
    return ok
    
}

Wl_Registry_Events_Callbacks :: map[u32]struct{
    callbacks: [Wl_Resgistry_Events]rawptr,
    user_data: [Wl_Resgistry_Events]rawptr
}

wl_registry_events_callbacks: Wl_Registry_Events_Callbacks

Wl_Registry_Event_Global_Callback :: proc(user_data: rawptr, wl_registry_id: u32, name: u32, interface: string, version: u32)
Wl_Registry_Event_Global_Remove_Callback :: proc(user_data: rawptr, wl_registry_id: u32, name: u32)

wl_registry_set_event_global_callback :: proc(wl_registry_id: u32, callback: Wl_Registry_Event_Global_Callback, user_data: rawptr) {
    if wl_registry_events_callbacks == nil {
        wl_registry_events_callbacks = make(Wl_Registry_Events_Callbacks)
    }

    if events, ok := wl_registry_events_callbacks[wl_registry_id]; ok {
        events.callbacks[.global] = transmute(rawptr)callback
        events.user_data[.global] = user_data
    } else {
        wl_registry_events_callbacks[wl_registry_id] = {
            callbacks = {.global = transmute(rawptr)callback, .global_remove = nil},
            user_data = {.global = user_data, .global_remove = nil}
        }
    }

    for i in wl_registry_events_callbacks {
        fmt.println(i)
        fmt.println(wl_registry_events_callbacks[i])
    }
}

wl_registry_set_event_global_remove_callback :: proc(wl_registry_id: u32, callback: Wl_Registry_Event_Global_Remove_Callback, user_data: rawptr) {
    if wl_registry_events_callbacks == nil {
        wl_registry_events_callbacks = make(Wl_Registry_Events_Callbacks)
    }
    
    if events, ok := wl_registry_events_callbacks[wl_registry_id]; ok {
        events.callbacks[.global_remove] = transmute(rawptr)callback
        events.user_data[.global_remove] = user_data
    } else {
         wl_registry_events_callbacks[wl_registry_id] = {
            callbacks = {.global = nil, .global_remove = transmute(rawptr)callback},
            user_data = {.global = nil, .global_remove = user_data}
        }
    }
}

wl_registry_dispatch :: proc(message: Message) {
    wl_registry_id := get_message_object_id(message)
    event := Wl_Resgistry_Events(get_message_opcode(message))
    callback, ok := wl_registry_events_callbacks[wl_registry_id]
    if !ok {
        return
    }

    switch event {
        case .global:
            index_on_args := 0
            name: u32
            interface: string
            version: u32
            name, index_on_args = read_uint_from_message_args(message)
            interface, index_on_args = read_string_from_message_args(message, index_on_args)
            version, index_on_args = read_uint_from_message_args(message, index_on_args)
            if callback.callbacks[.global] != nil {
                (transmute(Wl_Registry_Event_Global_Callback)callback.callbacks[.global])(callback.user_data[.global], wl_registry_id, name, interface, version)
            }
        case .global_remove:
            name: u32
            name, _ = read_uint_from_message_args(message)
            if callback.callbacks[.global_remove] != nil {
                (transmute(Wl_Registry_Event_Global_Remove_Callback)callback.callbacks[.global_remove])(callback.user_data[.global_remove], wl_registry_id, name)
            }
    }
}
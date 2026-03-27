package wayland

Wl_Callback_Events :: enum(u32) {
    done
}

Wl_Callback_Event_Done_Callback :: proc(user_data: rawptr, wl_callback_id: u32, callback_data: u32)

Wl_Callback_Events_Callbacks :: map[u32]struct {
    callback: Wl_Callback_Event_Done_Callback,
    user_data: rawptr,
}

wl_callback_events_callbacks: Wl_Callback_Events_Callbacks

wl_callback_set_done_callback :: proc(callback_id: u32, user_data: rawptr, callback: Wl_Callback_Event_Done_Callback) {
    if wl_callback_events_callbacks == nil {
        wl_callback_events_callbacks = make(Wl_Callback_Events_Callbacks)
    }

    wl_callback_events_callbacks[callback_id] = {
        callback = callback,
        user_data = user_data,
    }
}

wl_callback_dispatch :: proc(message: Message) {
    callback_id := get_message_object_id(message)
    if callback, ok := wl_callback_events_callbacks[callback_id]; ok {
        callback_data, _ := read_uint_from_message_args(message)
        wl_callback_events_callbacks[callback_id].callback(wl_callback_events_callbacks[callback_id].user_data, callback_id, callback_data)
        // limpando as coisas
        delete_key(&wl_callback_events_callbacks, callback_id)
        delete_id(callback_id)
    }
}
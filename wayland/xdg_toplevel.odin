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

Xdg_Toplevel_Error :: enum(u32) {
    invalid_resize_edge,
    invalid_parent,
    invalid_size,
}

Xdg_Toplevel_Resize_Edge :: enum(u32) {
    none,
    top,
    bottom,
    left,
    top_left,
    bottom_left,
    right,
    top_right,
    bottom_right,
}

Xdg_Toplevel_State :: enum(u32) {
    maximized = 1,
    fullscreen,
    resizing,
    activated,
    tiled_left,
    tiled_right,
    tiled_top,
    tiled_bottom,
    suspended,
    constrained_left,
    constrained_right,
    constrained_top,
    constrained_bottom,
}


Xdg_Toplevel_Wm_Capabilities :: enum(u32) {
    window_menu = 1, // show_window_menu is available
    maximize, // set_maximized
    fullscreen, // set_fullscreen and unset_fullscreen are available
    minimize, // set_minimized is available
}

Xdg_Toplevel_Event_Configure_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32, width: i32, height: i32, states: []Xdg_Toplevel_State)
Xdg_Toplevel_Event_Close_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32)
Xdg_Toplevel_Event_Configure_Bounds_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32, width: i32, height: i32)
Xdg_Toplevel_Event_Wm_Capabilities_Callback :: proc(user_data: rawptr, xdg_toplevel_id: u32, capabilities: []Xdg_Toplevel_Wm_Capabilities)

Xdg_Toplevel_Events_Callbacks :: map[u32]struct {
    callbacks: [Xdg_Toplevel_Events]rawptr,
    user_data: [Xdg_Toplevel_Events]rawptr,
}

xdg_toplevel_events_callbakcks: Xdg_Toplevel_Events_Callbacks = nil

xdg_toplevel_destroy :: proc(xdg_toplevel_id: u32) -> bool {
    delete_id(xdg_toplevel_id)
    delete_key(&xdg_toplevel_events_callbakcks, xdg_toplevel_id)
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.destroy))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_parent :: proc(xdg_toplevel_id: u32, parent_toplevel: u32) -> bool {
    msg: Message
    args_buf: [size_of(parent_toplevel)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_parent))
    write_uint_into_message_args(msg, parent_toplevel)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_title :: proc(xdg_toplevel_id: u32, title: string, allocator := context.allocator) -> bool {
    msg: Message
    size := len(title) + size_of(u32) + 1
    size = size + (size_of(u32) - (size % size_of(u32)))
    msg.arguments, _ = make([]u8, size, allocator)
    defer delete(msg.arguments)
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_title))
    write_string_into_message_args(msg, title)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_app_id :: proc(xdg_toplevel_id: u32, app_id: string, allocator := context.allocator) -> bool {
    msg: Message
    size := len(app_id) + size_of(u32) + 1
    size = size + (size_of(u32) - (size % size_of(u32)))
    msg.arguments, _ = make([]u8, size, allocator)
    defer delete(msg.arguments)
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_app_id))
    write_string_into_message_args(msg, app_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_show_window_menu :: proc(xdg_toplevel_id: u32, wl_seat_id: u32) -> bool {
    msg: Message
    args_buf: [size_of(wl_seat_id)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.show_window_menu))
    write_uint_into_message_args(msg, wl_seat_id)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_move :: proc(xdg_toplevel_id: u32, wl_seat_id: u32, serial: u32) -> bool {
    msg: Message
    args_buf: [size_of(wl_seat_id) + size_of(serial)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.move))
    args_index := write_uint_into_message_args(msg, wl_seat_id)
    args_index = write_uint_into_message_args(msg, serial, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_resize :: proc(xdg_toplevel_id: u32, wl_seat_id: u32, serial: u32, edges: Xdg_Toplevel_Resize_Edge) -> bool {
    msg: Message
    args_buf: [size_of(wl_seat_id) + size_of(serial) + size_of(edges)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.resize))
    args_index := write_uint_into_message_args(msg, wl_seat_id)
    args_index = write_uint_into_message_args(msg, serial, args_index)
    args_index = write_uint_into_message_args(msg, u32(edges), args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_max_size :: proc(xdg_toplevel_id: u32, width: i32, height: i32) -> bool {
    msg: Message
    args_buf: [size_of(width) + size_of(height)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_max_size))
    args_index := write_int_into_message_args(msg, width)
    args_index = write_int_into_message_args(msg, height, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_min_size :: proc(xdg_toplevel_id: u32, width: i32, height: i32) -> bool {
    msg: Message
    args_buf: [size_of(width) + size_of(height)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_min_size))
    args_index := write_int_into_message_args(msg, width)
    args_index = write_int_into_message_args(msg, height, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_maximized :: proc(xdg_toplevel_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_maximazed))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_unset_maximized :: proc(xdg_toplevel_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.unset_maximazed))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_fullscreen :: proc(xdg_toplevel_id: u32, output_id: ^u32) -> bool {
    msg: Message
    args_buf: [size_of(output_id^)]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_fullscreen))
    if (output_id == nil) {
        write_uint_into_message_args(msg, output_id^)
    } else {
        write_uint_into_message_args(msg, 0)
    }
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
    
}

xdg_toplevel_unset_fullscreen :: proc(xdg_toplevel_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.unset_fullscreen))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_minimized :: proc(xdg_toplevel_id: u32) -> bool {
    msg: Message
    set_message_object(&msg, xdg_toplevel_id)
    set_message_opcode(&msg, u16(Xdg_Toplevel_Requests.set_minimized))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

xdg_toplevel_set_configure_callback :: proc(xdg_toplevel_id: u32, user_data: rawptr, callback: Xdg_Toplevel_Event_Configure_Callback) {
    if xdg_toplevel_events_callbakcks == nil {
        xdg_toplevel_events_callbakcks = make(type_of(xdg_toplevel_events_callbakcks))
    }

    if callbacks, ok := &xdg_toplevel_events_callbakcks[xdg_toplevel_id]; ok {
        callbacks.callbacks[.configure] = rawptr(callback)
        callbacks.user_data[.configure] = user_data
    } else {
        xdg_toplevel_events_callbakcks[xdg_toplevel_id] = {
            callbacks = {
                .configure = rawptr(callback),
                .close = nil,
                .configure_bounds = nil,
                .wm_capabilities = nil,
            },
            user_data = {
                .configure = user_data,
                .close = nil,
                .configure_bounds = nil,
                .wm_capabilities = nil,
            }
        }
    }
}


xdg_toplevel_set_close_callback :: proc(xdg_toplevel_id: u32, user_data: rawptr, callback: Xdg_Toplevel_Event_Close_Callback) {
    if xdg_toplevel_events_callbakcks == nil {
        xdg_toplevel_events_callbakcks = make(type_of(xdg_toplevel_events_callbakcks))
    }

    if callbacks, ok := &xdg_toplevel_events_callbakcks[xdg_toplevel_id]; ok {
        callbacks.callbacks[.close] = rawptr(callback)
        callbacks.user_data[.close] = user_data
    } else {
        xdg_toplevel_events_callbakcks[xdg_toplevel_id] = {
            callbacks = {
                .configure = nil,
                .close = rawptr(callback),
                .configure_bounds = nil,
                .wm_capabilities = nil,
            },
            user_data = {
                .configure = nil,
                .close = user_data,
                .configure_bounds = nil,
                .wm_capabilities = nil,
            }
        }
    }
}

xdg_toplevel_set_configure_bounds_callback :: proc(xdg_toplevel_id: u32, user_data: rawptr, callback: Xdg_Toplevel_Event_Configure_Bounds_Callback) {
    if xdg_toplevel_events_callbakcks == nil {
        xdg_toplevel_events_callbakcks = make(type_of(xdg_toplevel_events_callbakcks))
    }

    if callbacks, ok := &xdg_toplevel_events_callbakcks[xdg_toplevel_id]; ok {
        callbacks.callbacks[.configure_bounds] = rawptr(callback)
        callbacks.user_data[.configure_bounds] = user_data
    } else {
        xdg_toplevel_events_callbakcks[xdg_toplevel_id] = {
            callbacks = {
                .configure = nil,
                .close = nil,
                .configure_bounds = rawptr(callback),
                .wm_capabilities = nil,
            },
            user_data = {
                .configure = nil,
                .close = nil,
                .configure_bounds = user_data,
                .wm_capabilities = nil,
            }
        }
    }
}


xdg_toplevel_set_wm_capabilities_callback :: proc(xdg_toplevel_id: u32, user_data: rawptr, callback: Xdg_Toplevel_Event_Wm_Capabilities_Callback) {
    if xdg_toplevel_events_callbakcks == nil {
        xdg_toplevel_events_callbakcks = make(type_of(xdg_toplevel_events_callbakcks))
    }

    if callbacks, ok := &xdg_toplevel_events_callbakcks[xdg_toplevel_id]; ok {
        callbacks.callbacks[.wm_capabilities] = rawptr(callback)
        callbacks.user_data[.wm_capabilities] = user_data
    } else {
        xdg_toplevel_events_callbakcks[xdg_toplevel_id] = {
            callbacks = {
                .configure = nil,
                .close = nil,
                .configure_bounds = nil,
                .wm_capabilities = rawptr(callback),
            },
            user_data = {
                .configure = nil,
                .close = nil,
                .configure_bounds = nil,
                .wm_capabilities = user_data,
            }
        }
    }
}

xdg_toplevel_dispatch :: proc(msg: Message) {
    xdg_toplevel_id := get_message_object_id(msg)
    event := Xdg_Toplevel_Events(get_message_opcode(msg))
    callbacks, ok := xdg_toplevel_events_callbakcks[xdg_toplevel_id]
    if !ok {
        return
    }
    switch event {
        case .configure:
            if callbacks.callbacks[.configure] == nil {
                return
            }
            width: i32
            height: i32
            states_buffer: []u8
            args_index := 0
            width, args_index = read_int_from_message_args(msg)
            height, args_index = read_int_from_message_args(msg, args_index)
            states_buffer, args_index = read_array_from_message_args(msg, args_index)
            Xdg_Toplevel_Event_Configure_Callback(callbacks.callbacks[.configure])(callbacks.user_data[.configure], xdg_toplevel_id, width, height, transmute([]Xdg_Toplevel_State)states_buffer)
        case .close:
            if callbacks.callbacks[.close] == nil {
                return
            }
            Xdg_Toplevel_Event_Close_Callback(callbacks.callbacks[.close])(callbacks.user_data[.close], xdg_toplevel_id)
        case .configure_bounds:
            if callbacks.callbacks[.configure_bounds] == nil {
                return
            }
            width: i32
            height: i32
            args_index := 0
            width, args_index = read_int_from_message_args(msg)
            height, args_index = read_int_from_message_args(msg, args_index)
            Xdg_Toplevel_Event_Configure_Bounds_Callback(callbacks.callbacks[.configure_bounds])(callbacks.user_data[.configure_bounds], xdg_toplevel_id, width, height)
        case .wm_capabilities:
            if callbacks.callbacks[.wm_capabilities] == nil {
                return
            }
            capabilities_buffer: []u8
            Xdg_Toplevel_Event_Wm_Capabilities_Callback(callbacks.callbacks[.wm_capabilities])(callbacks.user_data[.wm_capabilities], xdg_toplevel_id, transmute([]Xdg_Toplevel_Wm_Capabilities)capabilities_buffer)
    }
}
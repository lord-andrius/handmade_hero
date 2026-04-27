package wayland

Wl_Pointer_Requests :: enum(u32) {
    set_cursor,
    release,
}

Wl_Pointer_Events :: enum(u32) {
    enter,
    leave,
    motion,
    button,
    axis,
    frame,
    axis_source,
    axis_stop,
    axis_discrete,
    axis_value120,
    axis_relative_direction,
}

Wl_Pointer_Error :: enum(u32) {
    role,
}

Wl_Pointer_Button_State :: enum(u32) {
    released,
    pressed,
}

Wl_Pointer_Axis :: enum(u32) {
    vertical_scroll,
    horizontal_scroll,
}

Wl_Pointer_Axis_Source :: enum(u32) {
    wheel,
    finger,
    continuous,
    wheel_tilt,
}

Wl_Pointer_Axis_Relative_Direction :: enum(u32) {
    identical,
    inverted,
}

Wl_Pointer_Enter_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    surface: u32,
    surface_x: fixed,
    surface_y: fixed,
)

Wl_Pointer_Leave_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    serial: u32,
    surface: u32,
)

Wl_Pointer_Motion_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    time: u32,
    surface_x: u32,
    surface_y: u32,
)

Wl_Pointer_Button_Event_Callback :: proc(
    user_data: rawptr,  
    wl_pointer: u32,
    serial: u32,
    time: u32,
    button: u32, 
    state: Wl_Pointer_Button_State,
)

Wl_Pointer_Axis_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    time: u32,
    axis: Wl_Pointer_Axis,
    value: fixed,
)

Wl_Pointer_Frame_Event_Callback :: proc(user_data: rawptr, wl_pointer: u32)

Wl_Pointer_Axis_Source_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis_source: Wl_Pointer_Axis_Source,
)

Wl_Pointer_Axis_Stop_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    time: u32,
    axis: Wl_Pointer_Axis,
)

Wl_Pointer_Axis_Discrete_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis: Wl_Pointer_Axis,
    discrete: i32,
)

Wl_Pointer_Axis_Value120_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis: Wl_Pointer_Axis,
    value120: i32,
)

Wl_Pointer_Axis_Relative_Direction_Event_Callback :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis: Wl_Pointer_Axis,
    direction: Wl_Pointer_Axis_Relative_Direction,
)

Wl_Pointer_Callbacks :: map[u32]struct {
    callbacks: [Wl_Pointer_Events]rawptr,
    user_data: [Wl_Pointer_Events]rawptr,
}

wl_pointer_callbacks: Wl_Pointer_Callbacks = nil

wl_pointer_set_cursor :: proc(wl_pointer: u32, serial: u32, surface: u32, hotspot_x, hotspot_y: i32) -> bool {
    msg: Message
    args_buffer: [size_of(serial) + size_of(surface) + size_of(hotspot_x) + size_of(hotspot_y)]u8
    msg.arguments = args_buffer[:]
    set_message_object(&msg, wl_pointer)
    set_message_opcode(&msg, u16(Wl_Pointer_Requests.set_cursor))
    args_index := write_uint_into_message_args(msg, serial)
    args_index = write_uint_into_message_args(msg, surface, args_index)
    args_index = write_int_into_message_args(msg, hotspot_x, args_index)
    args_index = write_int_into_message_args(msg, hotspot_y, args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

wl_pointer_release :: proc(wl_pointer: u32) -> bool {
    msg: Message
    set_message_object(&msg, wl_pointer)
    set_message_opcode(&msg, u16(Wl_Pointer_Requests.release))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    return ok
}

wl_pointer_set_enter_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Enter_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.enter] = rawptr(callback)
        c.user_data[.enter] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.enter = rawptr(callback)},
            user_data = #partial {.enter = user_data}
        }
    }
}

wl_pointer_set_leave_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Leave_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.leave] = rawptr(callback)
        c.user_data[.leave] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.leave = rawptr(callback)},
            user_data = #partial {.leave = user_data},
        }
    }
}

wl_pointer_set_motion_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Motion_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.motion] = rawptr(callback)
        c.user_data[.motion] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.motion = rawptr(callback)},
            user_data = #partial {.motion = user_data},
        }
    }
}

wl_pointer_set_button_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Button_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.button] = rawptr(callback)
        c.user_data[.button] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.button = rawptr(callback)},
            user_data = #partial {.button = user_data},
        }
    }
}

wl_pointer_set_axis_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis] = rawptr(callback)
        c.user_data[.axis] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis = rawptr(callback)},
            user_data = #partial {.axis = user_data},
        }
    }
}

wl_pointer_set_frame_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Frame_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.frame] = rawptr(callback)
        c.user_data[.frame] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.frame = rawptr(callback)},
            user_data = #partial {.frame = user_data},
        }
    }
}

wl_pointer_set_axis_source_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Source_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis_source] = rawptr(callback)
        c.user_data[.axis_source] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis_source = rawptr(callback)},
            user_data = #partial {.axis_source = user_data},
        }
    }
}

wl_pointer_set_axis_stop_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Stop_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis_stop] = rawptr(callback)
        c.user_data[.axis_stop] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis_stop = rawptr(callback)},
            user_data = #partial {.axis_stop = user_data},
        }
    }
}

wl_pointer_set_axis_discrete_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Discrete_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis_discrete] = rawptr(callback)
        c.user_data[.axis_discrete] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis_discrete = rawptr(callback)},
            user_data = #partial {.axis_discrete = user_data},
        }
    }
}

wl_pointer_set_axis_value120_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Value120_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis_value120] = rawptr(callback)
        c.user_data[.axis_value120] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis_value120 = rawptr(callback)},
            user_data = #partial {.axis_value120 = user_data},
        }
    }
}

wl_pointer_set_axis_relative_direction_callback :: proc(wl_pointer: u32, user_data: rawptr, callback: Wl_Pointer_Axis_Discrete_Event_Callback) {
    if wl_pointer_callbacks == nil {
        wl_pointer_callbacks = make(type_of(wl_pointer_callbacks))
    }

    if c, ok := &wl_pointer_callbacks[wl_pointer]; ok {
        c.callbacks[.axis_relative_direction] = rawptr(callback)
        c.user_data[.axis_relative_direction] = user_data
    } else {
        wl_pointer_callbacks[wl_pointer] = {
            callbacks = #partial {.axis_relative_direction = rawptr(callback)},
            user_data = #partial {.axis_relative_direction = user_data},
        }
    }
}


wl_pointer_dispatch :: proc(msg: Message) {
    wl_pointer := get_message_object_id(msg)
    event := Wl_Pointer_Events(get_message_opcode(msg))

    callback, ok := wl_pointer_callbacks[wl_pointer]
    if !ok {
        return
    }

    switch event {
        case .enter:
            if callback.callbacks[.enter] == nil do return
            args_index := 0
            serial: u32
            surface: u32
            surface_x: fixed
            surface_y: fixed
            serial, args_index = read_uint_from_message_args(msg)
            surface, args_index = read_uint_from_message_args(msg, args_index)
            surface_x, args_index = read_fixed_from_message_args(msg, args_index)
            surface_y, args_index = read_fixed_from_message_args(msg, args_index)
            Wl_Pointer_Enter_Event_Callback(callback.callbacks[.enter])(
                callback.user_data[.enter],
                wl_pointer,
                surface,
                surface_x,
                surface_y
            )
        case .leave:
            if callback.callbacks[.leave] == nil do return
            args_index := 0
            serial: u32
            surface: u32
            serial, args_index = read_uint_from_message_args(msg)
            surface, args_index = read_uint_from_message_args(msg, args_index)
            Wl_Pointer_Leave_Event_Callback(callback.callbacks[.leave])(
                callback.user_data[.leave],
                wl_pointer,
                serial,
                surface,
            )
        case .motion:
            if callback.callbacks[.motion] == nil do return
            args_index := 0
            time: u32
            surface_x: fixed
            surface_y: fixed
            time, args_index = read_uint_from_message_args(msg)
            surface_x, args_index = read_fixed_from_message_args(msg, args_index)
            surface_y, args_index = read_fixed_from_message_args(msg, args_index)
            Wl_Pointer_Motion_Event_Callback(callback.callbacks[.motion])(
                callback.user_data[.motion],
                wl_pointer,
                time,
                surface_x,
                surface_y,
            )
        case .button:
            if callback.callbacks[.button] == nil do return
            args_index := 0
            serial: u32
            time: u32
            button: u32
            state: u32
            serial, args_index = read_uint_from_message_args(msg)
            time, args_index = read_uint_from_message_args(msg, args_index)
            button, args_index = read_uint_from_message_args(msg, args_index)
            state, args_index = read_uint_from_message_args(msg, args_index)
            Wl_Pointer_Button_Event_Callback(callback.callbacks[.button])(
                callback.user_data[.button],
                wl_pointer,
                serial,
                time,
                button,
                Wl_Pointer_Button_State(state),
            )
        case .axis:
            if callback.callbacks[.axis] == nil do return
            args_index := 0
            time: u32
            axis: u32
            value: fixed
            time, args_index = read_uint_from_message_args(msg)
            axis, args_index = read_uint_from_message_args(msg, args_index)
            value, args_index = read_fixed_from_message_args(msg, args_index)
            Wl_Pointer_Axis_Event_Callback(callback.callbacks[.axis])(
                callback.user_data[.axis],
                wl_pointer,
                time,
                Wl_Pointer_Axis(axis),
                value,
            )
        case .frame:
            if callback.callbacks[.frame] == nil do return
            Wl_Pointer_Frame_Event_Callback(callback.callbacks[.frame])(callback.user_data[.frame], wl_pointer)
        case .axis_source:
            if callback.callbacks[.axis_source] == nil do return
            axis_source, _ := read_uint_from_message_args(msg)
            Wl_Pointer_Axis_Source_Event_Callback(callback.callbacks[.axis_source])(
                callback.user_data[.axis_source],
                wl_pointer,
                Wl_Pointer_Axis_Source(axis_source)
            )
        case .axis_stop:
            if callback.callbacks[.axis_stop] == nil do return
            args_index := 0
            time: u32
            axis: u32
            time, args_index = read_uint_from_message_args(msg)
            axis, args_index = read_uint_from_message_args(msg, args_index)
            Wl_Pointer_Axis_Stop_Event_Callback(callback.callbacks[.axis_stop])(
                callback.user_data[.axis_stop],
                wl_pointer,
                time,
                Wl_Pointer_Axis(axis)
            )
        case .axis_discrete:
            if callback.callbacks[.axis_stop] == nil do return
            args_index := 0
            axis: u32
            discrete: i32
            axis, args_index = read_uint_from_message_args(msg)
            discrete, args_index = read_int_from_message_args(msg, args_index)
            Wl_Pointer_Axis_Discrete_Event_Callback(callback.callbacks[.axis_discrete])(
                callback.user_data[.axis_discrete],
                wl_pointer,
                Wl_Pointer_Axis(axis),
                discrete,
            )
        case .axis_value120:
            if callback.callbacks[.axis_value120] == nil do return
            args_index := 0
            axis: u32
            valu120: i32
            axis, args_index = read_uint_from_message_args(msg)
            valu120, args_index = read_int_from_message_args(msg, args_index)
            Wl_Pointer_Axis_Value120_Event_Callback(callback.callbacks[.axis_value120])(
                callback.user_data[.axis_value120],
                wl_pointer,
                Wl_Pointer_Axis(axis),
                valu120,
            )
        case .axis_relative_direction:
            if callback.callbacks[.axis_relative_direction] == nil do return
            args_index := 0
            axis: u32
            direction: u32
            axis, args_index = read_uint_from_message_args(msg)
            direction, args_index = read_uint_from_message_args(msg, args_index)
            Wl_Pointer_Axis_Relative_Direction_Event_Callback(callback.callbacks[.axis_relative_direction])(
                callback.user_data[.axis_relative_direction],
                wl_pointer,
                Wl_Pointer_Axis(axis),
                Wl_Pointer_Axis_Relative_Direction(direction),
            )

    }
}
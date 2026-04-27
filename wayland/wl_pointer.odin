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

Wl_Pointer_Axis_Source_Event :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis_source: Wl_Pointer_Axis_Source,
)

Wl_Pointer_Axis_Stop_Event :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    time: u32,
    axis: Wl_Pointer_Axis,
)

Wl_Pointer_Axis_Discrete_Event :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    time: u32,
    axis: Wl_Pointer_Axis,
    discrete: i32,
)

Wl_Pointer_Axis_Value120_Event :: proc(
    user_data: rawptr,
    wl_pointer: u32,
    axis: Wl_Pointer_Axis,
    value120: i32,
)

Wl_Pointer_Axis_Relative_Direction_Event :: proc(
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



wl_pointer_dispatch :: proc(msg: Message) {}
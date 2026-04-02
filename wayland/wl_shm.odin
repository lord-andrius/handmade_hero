package wayland

import "core:sys/posix"
import "core:sys/linux"
import "base:runtime"
import "core:mem"
import "../shared"



Wl_Shm_Error :: enum(u32) {
    invalid_format,
    invalid_stride,
    invalid_fd,
}

Wl_Shm_Format :: enum(u32) {
    argb8888 = 0,
    xrgb8888 = 1,
    c8 = 0x20203843,
    rgb332 = 0x38424752,
    bgr233 = 0x38524742,
    xrgb4444 = 0x32315258,
    xbgr4444 = 0x32314258,
    rgbx4444 = 0x32315852,
    bgrx4444 = 0x32315842,
    argb4444 = 0x32315241,
    abgr4444 = 0x32314241,
    rgba4444 = 0x32314152,
    bgra4444 = 0x32314142,
    xrgb1555 = 0x35315258,
    xbgr1555 = 0x35314258,
    rgbx5551 = 0x35315852,
    bgrx5551 = 0x35315842,
    argb1555 = 0x35315241,
    abgr1555 = 0x35314241,
    rgba5551 = 0x35314152,
    bgra5551 = 0x35314142,
    rgb565 = 0x36314752,
    bgr565 = 0x36314742,
    rgb888 = 0x34324752,
    bgr888 = 0x34324742,
    xbgr8888 = 0x34324258,
    rgbx8888 = 0x34325852,
    bgrx8888 = 0x34325842,
    abgr8888 = 0x34324241,
    rgba8888 = 0x34324152,
    bgra8888 = 0x34324142,
    xrgb2101010 = 0x30335258,
    xbgr2101010 = 0x30334258,
    rgbx1010102 = 0x30335852,
    bgrx1010102 = 0x30335842,
    argb2101010 = 0x30335241,
    abgr2101010 = 0x30334241,
    rgba1010102 = 0x30334152,
    bgra1010102 = 0x30334142,
    yuyv = 0x56595559,
    yvyu = 0x55595659,
    uyvy = 0x59565955,
    vyuy = 0x59555956,
    ayuv = 0x56555941,
    nv12 = 0x3231564e,
    nv21 = 0x3132564e,
    nv16 = 0x3631564e,
    nv61 = 0x3136564e,
    yuv410 = 0x39565559,
    yvu410 = 0x39555659,
    yuv411 = 0x31315559,
    yvu411 = 0x31315659,
    yuv420 = 0x32315559,
    yvu420 = 0x32315659,
    yuv422 = 0x36315559,
    yvu422 = 0x36315659,
    yuv444 = 0x34325559,
    yvu444 = 0x34325659,
    r8 = 0x20203852,
    r16 = 0x20363152,
    rg88 = 0x38384752,
    gr88 = 0x38385247,
    rg1616 = 0x32334752,
    gr1616 = 0x32335247,
    xrgb16161616f = 0x48345258,
    xbgr16161616f = 0x48344258,
    argb16161616f = 0x48345241,
    abgr16161616f = 0x48344241,
    xyuv8888 = 0x56555958,
    vuy888 = 0x34325556,
    vuy101010 = 0x30335556,
    y210 = 0x30313259,
    y212 = 0x32313259,
    y216 = 0x36313259,
    y410 = 0x30313459,
    y412 = 0x32313459,
    y416 = 0x36313459,
    xvyu2101010 = 0x30335658,
    xvyu12_16161616 = 0x36335658,
    xvyu16161616 = 0x38345658,
    y0l0 = 0x304c3059,
    x0l0 = 0x304c3058,
    y0l2 = 0x324c3059,
    x0l2 = 0x324c3058,
    yuv420_8bit = 0x38305559,
    yuv420_10bit = 0x30315559,
    xrgb8888_a8 = 0x38415258,
    xbgr8888_a8 = 0x38414258,
    rgbx8888_a8 = 0x38415852,
    bgrx8888_a8 = 0x38415842,
    rgb888_a8 = 0x38413852,
    bgr888_a8 = 0x38413842,
    rgb565_a8 = 0x38413552,
    bgr565_a8 = 0x38413542,
    nv24 = 0x3432564e,
    nv42 = 0x3234564e,
    p210 = 0x30313250,
    p010 = 0x30313050,
    p012 = 0x32313050,
    p016 = 0x36313050,
    axbxgxrx106106106106 = 0x30314241,
    nv15 = 0x3531564e,
    q410 = 0x30313451,
    q401 = 0x31303451,
    xrgb16161616 = 0x38345258,
    xbgr16161616 = 0x38344258,
    argb16161616 = 0x38345241,
    abgr16161616 = 0x38344241,
    c1 = 0x20203143,
    c2 = 0x20203243,
    c4 = 0x20203443,
    d1 = 0x20203144,
    d2 = 0x20203244,
    d4 = 0x20203444,
    d8 = 0x20203844,
    r1 = 0x20203152,
    r2 = 0x20203252,
    r4 = 0x20203452,
    r10 = 0x20303152,
    r12 = 0x20323152,
    avuy8888 = 0x59555641,
    xvuy8888 = 0x59555658,
    p030 = 0x30333050,
}

Wl_Shm_Errors :: enum(u32) {
    invalid_format,
    invalid_stride,
    invalid_fd,
}

Wl_Shm_Requests :: enum(u32) {
    create_pool,
    relese,
}

wl_Shm_Events :: enum(u32) {
    format,
}

bind_wl_shm_global_object :: proc(wl_registry_id: u32, wl_shm_name: u32, interface: string, version: u32) -> u32 {
    id := generate_new_id(wl_shm_dispatch)
    wl_registry_bind(wl_registry_id, wl_shm_name, interface, version, id)
    return id
}

wl_shm_create_pool :: proc(wl_shm_id: u32, shared_buffer: ^shared.Shared_Buffer, size_in_bytes: int) -> (Wl_Shm_Pool, bool) {
    assert(size_in_bytes != 0)
    id := generate_new_id(nil) // shm_poll não tem eventos
    control: [size_of(posix.cmsghdr) + size_of(linux.Fd)]u8
    csmg := transmute(^posix.cmsghdr)&control[0]
    csmg.cmsg_len = len(control)
    csmg.cmsg_level = posix.SOL_SOCKET
    csmg.cmsg_type = posix.SCM_RIGHTS
    (transmute(^linux.Fd)(posix.CMSG_DATA(csmg)))^ = shared_buffer.fd
    
    msg: Message
    args_buf: [12]u8
    msg.arguments = args_buf[:]
    set_message_object(&msg, wl_shm_id)
    set_message_opcode(&msg, u16(Wl_Shm_Requests.create_pool))
    args_index := write_uint_into_message_args(msg, id)
    args_index = write_uint_into_message_args(msg, u32(shared_buffer.fd), args_index)
    args_index = write_int_into_message_args(msg, i32(size_in_bytes), args_index)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg, control[:])
    return Wl_Shm_Pool{shared_buffer = shared_buffer, wl_shm_id = id}, ok
}

// basicamente deleta o wl_shm mas os objetos criados por ele
// não são tocados.
wl_shm_release :: proc(wl_shm_id: u32) -> bool{
    msg: Message
    set_message_object(&msg, wl_shm_id)
    set_message_opcode(&msg, u16(Wl_Shm_Requests.relese))
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    if ok {
        delete_id(wl_shm_id)
    }
    return ok
}

Wl_Shm_Event_Format_Callback :: proc(user_data: rawptr, wl_shm_id: u32, format: Wl_Shm_Format)
Wl_Shm_Events_Callbacks :: map[u32]struct {
    callback: Wl_Shm_Event_Format_Callback,
    user_data: rawptr,
}

wl_shm_events_callbacks: Wl_Shm_Events_Callbacks = nil

wl_shm_set_format_callback :: proc(wl_shm_id: u32, user_data: rawptr, callback: Wl_Shm_Event_Format_Callback) {
    if wl_shm_events_callbacks == nil {
        wl_shm_events_callbacks = make(Wl_Shm_Events_Callbacks)
    }
    wl_shm_events_callbacks[wl_shm_id] = {
        callback = callback,
        user_data = user_data,
    }
}


wl_shm_dispatch :: proc(msg: Message) {
    if wl_shm_events_callbacks == nil do return
    wl_shm_id := get_message_object_id(msg)
    // não tem motivo de verificar o opcode pq só tem um evento XD
    if callback, ok := wl_shm_events_callbacks[wl_shm_id]; ok {
        format, _ := read_uint_from_message_args(msg)
        callback.callback(callback.user_data, wl_shm_id, Wl_Shm_Format(format))
    }
}
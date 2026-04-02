package wayland

import "base:runtime"
import "../shared"

Wl_Shm_Pool :: struct {
    wl_shm_id: u32,
    shared_buffer: ^shared.Shared_Buffer,
}

Wl_Shm_Pool_Requests :: enum(u32) {
    create_buffer,
    destroy,
    resize, // só pode aumentar
}

wl_shm_pool_create_buffer :: proc(wl_shm_pool: Wl_Shm_Pool, offset: i32, width: i32, height: i32, stride: i32, format: Wl_Shm_Format) -> (Wl_Buffer, bool) {
    assert(int(offset + (width * height)) <= len(wl_shm_pool.shared_buffer.data))
    new_buffer_id := generate_new_id(wl_buffer_dispatch)
    msg: Message
    set_message_object(&msg, wl_shm_pool.wl_shm_id)
    set_message_opcode(&msg, u16(Wl_Shm_Pool_Requests.create_buffer))
    args_buffer: [size_of(u32) + (size_of(i32) * 4) + size_of(u32)]u8
    msg.arguments = args_buffer[:]
    index_arg := write_uint_into_message_args(msg, new_buffer_id)
    index_arg = write_int_into_message_args(msg, offset, index_arg)
    index_arg = write_int_into_message_args(msg, width, index_arg)
    index_arg = write_int_into_message_args(msg, height, index_arg)
    index_arg = write_int_into_message_args(msg, stride, index_arg)
    index_arg = write_uint_into_message_args(msg, u32(format), index_arg)
    set_message_length_based_on_args_length(&msg)
    _, ok := write_message(msg)
    buffer: Wl_Buffer
    buffer.shared_buffer = wl_shm_pool.shared_buffer
    buffer.data = transmute([]u8)runtime.Raw_Slice {
        data = &wl_shm_pool.shared_buffer.data[offset],
        len = int(offset + (width * height))
    }
    shared.add_one_user_to_shared_buffer(wl_shm_pool.shared_buffer)
    return buffer, ok
}

wl_shm_pool_destroy :: proc(wl_shm_pool: Wl_Shm_Pool) {
    delete_id(wl_shm_pool.wl_shm_id)
}


// só pode aumentar
wl_shm_pool_resize :: proc(wl_shm_pool: Wl_Shm_Pool, new_size: int) {
    assert(new_size > len(wl_shm_pool.shared_buffer.data))
}
package wayland

import "../shared"

Wl_Buffer :: struct {
    shared_buffer: ^shared.Shared_Buffer,
    data: []u8
}

wl_buffer_dispatch :: proc(msg: Message) {

}
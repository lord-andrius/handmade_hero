package wayland

import "core:os"
import "core:sys/linux"
import "core:strconv"
import "core:mem"
import "core:slice"
import "base:runtime"
import "core:fmt"

connect :: proc() -> (linux.Fd, bool) {
    defer free_all(context.temp_allocator)

    xdg_runtime_dir, found_xdg_runtime_dir := os.lookup_env_alloc("XDG_RUNTIME_DIR", context.temp_allocator)
    if (!found_xdg_runtime_dir) {
        return 0, false
    }


    wayland_display, found_wayland_display := os.lookup_env_alloc("WAYLAND_DISPLAY", context.temp_allocator)
    if (!found_wayland_display) {
        wayland_display = "wayland-0"
    }

    full_wayland_sock_path := fmt.caprintf("%s/%s", xdg_runtime_dir, wayland_display);



    socket_addr := linux.Sock_Addr_Un {
        sun_family =  .UNIX
    }


    mem.copy(transmute(rawptr)&socket_addr.sun_path[0], &(transmute(runtime.Raw_Cstring)full_wayland_sock_path).data[0], len(full_wayland_sock_path))


    wayland_socket_file_descriptor, socket_erro := linux.socket(.UNIX, .STREAM, {}, .HOPOPT)
    if (socket_erro != .NONE) {
        return 0, false
    }

    if err := linux.connect(wayland_socket_file_descriptor, &socket_addr); err != .NONE {
        return 0, false
    }

    return wayland_socket_file_descriptor, true
}

// números decimais
Fixed :: u32

Object :: u32

New_Id :: Object


//a diferença da string para o array é que a string tem um byte a mais que é o '\0' antes do conteúdo no data
String :: struct {
    length: u32,
    data: ^u8
}

Array :: struct {
    length: u32,
    data: ^u8
}

Message :: struct {
    header: u64,
    arguments: []u8
}

MESSAGE_HEADER_SIZE_IN_BYTES :: 8

// Tô deixando isso aqui para futuras referências...
/*
make_message :: proc(object: u32, opcode: u16, arguments: []u8) -> Message {
    message: Message
    message.header |= u64(object)
    // o tamanho da mensagem incluí o cabeçalho
    message.header |= u64(opcode) << 32
    message.header |= u64((len(arguments) + 8) << 48)
    message.arguments = arguments
    return message
}
*/

get_message_object_id :: proc(message: Message) -> u32 {
    return cast(u32)(message.header & 0xFFFFFFFF)
}

get_message_opcode :: proc(message: Message) -> u16 {
    return cast(u16)((message.header >> 32) & 0xFFFF)
}

get_message_length :: proc(message: Message) -> u16 {
    return cast(u16)((message.header >> 48) & 0xFFFF)
}

set_message_object :: proc(message: ^Message, object: u32) {
    message.header |= u64(object)
}

set_message_opcode :: proc(message: ^Message, opcode: u16) {
    message.header |= u64(opcode) << 32
}

set_message_length :: proc(message: ^Message, length: u16) {
    message.header |= u64(length) << 48
}

set_message_length_based_on_args_length :: proc(message: ^Message) {
    set_message_length(message, u16(len(message.arguments) + MESSAGE_HEADER_SIZE_IN_BYTES))
}


write_message :: proc(fd: linux.Fd, message: Message) -> (int, bool) {
    message := message
    message_bytes, err := make([]u8, get_message_length(message), context.temp_allocator)
    defer free_all(context.temp_allocator)

    mem.copy(transmute(rawptr)&message_bytes[0], &message.header, 8)
    mem.copy(transmute(rawptr)&message_bytes[8], transmute(rawptr)&message.arguments[0], len(message.arguments))

    

    bytes_written, erro  := linux.write(fd, message_bytes)
    if erro != .NONE {
        return 0, false
    }

    return bytes_written, true
}


read_message :: proc(fd: linux.Fd) -> (Message, bool) {
    message: Message
    header_buf: runtime.Raw_Slice
    header_buf.data = rawptr(&message.header)
    header_buf.len = 8

    bytes_lidos, erro := linux.read(fd, transmute([]u8)header_buf)
    if erro != .NONE {
        return message, false
    }

    // -8 porque no length conta o header
    message_bytes, err := make([]u8, get_message_length(message) - MESSAGE_HEADER_SIZE_IN_BYTES)

    bytes_lidos, erro = linux.read(fd, message_bytes)
    message.arguments = message_bytes
    return message, true

}


read_uint_from_message_args :: proc(message: Message, index_on_arguments: int = 0) -> (u32, int) {
 // remove padding
 index_on_arguments := index_on_arguments + (index_on_arguments % 4)
 return (transmute(^u32)(&message.arguments[index_on_arguments]))^, index_on_arguments + size_of(u32)
}

read_int_from_message_args :: proc(message: Message, index_on_arguments: int = 0) -> (i32, int) {
 index_on_arguments := index_on_arguments + (index_on_arguments % 4)
 return (transmute(^i32)(&message.arguments[index_on_arguments]))^, index_on_arguments + size_of(i32)
}

read_string_from_message_args :: proc(message: Message, index_on_arguments: int = 0) -> (string, int) {
    index_on_arguments := index_on_arguments + (index_on_arguments % 4)
    string_length: u32
    string_length, index_on_arguments = read_uint_from_message_args(message, index_on_arguments)
    str: runtime.Raw_String
    str.data = transmute([^]byte)(&message.arguments[index_on_arguments])
    str.len = int(string_length)
    // uso +1 porque as strings do wayland tem sentinela nulo(\0) no final.
    return transmute(string)str, index_on_arguments + int(string_length + 1)
}

// É responsabilidade, de quem chama a função garantir que tem espaço
// suficiente para todos os argumentos.
// NOTA: Quando for allocar conte com paddings
write_uint_into_message_args :: proc(message: Message, arg: u32, index_on_arguments: int = 0) -> int {
    // isso garanti que o alinhamento dos bytes estejam corretos
    index_on_arguments := index_on_arguments + (index_on_arguments % 4)
    // garantindo que tem espaço nos argumentos
    assert(index_on_arguments + size_of(arg) <= len(message.arguments))
    (transmute(^u32)&message.arguments[index_on_arguments])^ = arg
    index_on_arguments += size_of(arg)
    return index_on_arguments
}

write_int_into_message_args :: proc(message: Message, arg: i32, index_on_arguments: int = 0) -> int {
    index_on_arguments := index_on_arguments + (index_on_arguments % 4)
    assert(index_on_arguments + size_of(arg) <= len(message.arguments))
    (transmute(^i32)&message.arguments[index_on_arguments])^ = arg
    index_on_arguments += size_of(arg)
    return index_on_arguments
}

write_string_into_message_args :: proc(message: Message, arg: string, index_on_arguments: int = 0) -> int{
    index_on_arguments := index_on_arguments + (index_on_arguments % 4)
    // o mais um é para o byte nulo.
    assert(index_on_arguments + size_of(u32) + len(arg) + 1 < len(message.arguments))
    // como strings no wayland tem são: {tamanho: u32, data: [u8...], \0} temos que colocar o tamnhho.
    string_length := len(arg)
    index_on_arguments = write_uint_into_message_args(message, u32(len(arg)), index_on_arguments)
    mem.copy(transmute(rawptr)&message.arguments[index_on_arguments], (transmute(runtime.Raw_String)arg).data, len(arg))
    index_on_arguments += len(arg)
    // escrevendo o byte nulo depois do conteúdo da string.
    message.arguments[index_on_arguments] = 0
    index_on_arguments += 1
    return index_on_arguments
}
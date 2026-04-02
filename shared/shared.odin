package shared

import "core:sys/linux"
import "base:runtime"
import "core:path/slashpath"
import "core:strings"

Shared_Buffer :: struct {
    fd: linux.Fd,
    data: []u8,
    reference_count: u32,
}

create_shared_buffer :: proc(name: string, size_in_bytes: uint, allocator: runtime.Allocator = context.allocator) -> (^Shared_Buffer, bool) {
    defer free_all(context.temp_allocator)
    erro: linux.Errno
    fd: linux.Fd
    path := slashpath.join([]string{"/dev/shm", name}, context.temp_allocator)    
    cpath, allocation_err := strings.clone_to_cstring(path, context.temp_allocator)
    addr: rawptr
    if allocation_err != .None {
        return nil, false
    }

    fd, erro = linux.open(cpath, {.CREAT, .RDWR, .NOFOLLOW, .CLOEXEC, .NONBLOCK}, {.IRUSR, .IWUSR, .IRGRP, .IWGRP, .IROTH, .IWOTH})
    if erro != .NONE {
        return nil, false
    }

    if linux.ftruncate(fd, i64(size_in_bytes)) != .NONE {
        linux.close(fd)
        return nil, false
    }

    addr, erro = linux.mmap(0, size_in_bytes, {.READ, .WRITE}, {.SHARED}, fd, 0)
    if erro != .NONE {
        return nil, false
    }

    shared := new(Shared_Buffer, allocator)
    shared.fd = fd
    shared.data = transmute([]u8)runtime.Raw_Slice{data = addr, len = int(size_in_bytes)}
    return shared, true 
}

add_one_user_to_shared_buffer :: proc(sh: ^Shared_Buffer) {
    sh.reference_count += 1
}

destroy_shared_buffer :: proc(sh: ^Shared_Buffer) {
    if sh.reference_count > 0 {
        sh.reference_count -= 1
    }

    if sh.reference_count == 0 {
        linux.munmap(&sh.data[0], len(sh.data))
        linux.close(sh.fd)
        free(sh)
    }
}

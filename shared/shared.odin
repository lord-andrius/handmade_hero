package shared

import "core:sys/linux"
import "base:runtime"
import "core:path/slashpath"
import "core:strings"

Shared_Buffer :: struct {
    fd: linux.Fd,
    data: []u8,
}

create_shared_buffer :: proc(name: string, size_in_bytes: uint) -> (Shared_Buffer, bool) {
    defer free_all(context.temp_allocator)
    erro: linux.Errno
    fd: linux.Fd
    path := slashpath.join([]string{"/dev/shm", name}, context.temp_allocator)    
    cpath, allocation_err := strings.clone_to_cstring(path, context.temp_allocator)
    addr: rawptr
    if allocation_err != .None {
        return {fd = linux.Fd(0), data = []u8{}}, false
    }

    fd, erro = linux.open(cpath, {.CREAT, .RDWR, .NOFOLLOW, .CLOEXEC, .NONBLOCK}, {.IRUSR, .IWUSR, .IRGRP, .IWGRP, .IROTH, .IWOTH})
    if erro != .NONE {
        return {fd = linux.Fd(0), data = []u8{}}, false
    }

    if linux.ftruncate(fd, i64(size_in_bytes)) != .NONE {
        linux.close(fd)
        return {fd = linux.Fd(0), data = []u8{}}, false
    }

    addr, erro = linux.mmap(0, size_in_bytes, {.READ, .WRITE}, {.SHARED}, fd, 0)
    if erro != .NONE {
        return {fd = linux.Fd(0), data = []u8{}}, false
    }

    return {fd = fd, data = transmute([]u8)runtime.Raw_Slice{data = addr, len = int(size_in_bytes)}}, false 
}

destroy_shared_buffer :: proc(sh: Shared_Buffer) {
    linux.munmap(&sh.data[0], len(sh.data))
    linux.close(sh.fd)
}

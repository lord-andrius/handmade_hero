package wayland

Xdg_Wm_Base_Errors :: enum(u32) {
    role,
    defunc_surfaces,
    not_the_topmost_popup,
    invalid_popup_parent,
    invalid_surface_state,
    invalid_positioner,
    unresponsive,
}

Xdg_Wm_Base_Requests :: enum(u32) {
    destroy,
    create_positioner,
    get_xdg_surface, 
    pong,
}

Xdg_Wm_Base_Events :: enum(u32) {
    ping,
}

xdg_wm_base_get_xdg_surface :: proc(xdg_wm_base_id: u32, wl_surface_id: u32) -> (u32, bool) {
    new_xdg_surface_id := generate_new_id(xdg_surface_dispatch)

    // STUB
    return 0, true
}

xdg_wm_base_dispatch :: proc(message: u32) {

}
package imdd3

Platform_Interface :: struct {
    init: proc(),
    destroy: proc(),

    get_viewport: proc() -> [2]i32,
    get_is_focused: proc() -> bool,
    get_key_state: proc(scancode: Scancode) -> bool,
    get_mouse_position: proc() -> [2]f32,
    get_mouse_down: proc(button: int) -> bool,
}

Platform :: struct {
    interface: Platform_Interface,
}

platform: Platform

init_platform :: proc(interface: Platform_Interface) {
    platform.interface = interface
    platform.interface.init()
}

destroy_platform :: proc() {
    platform.interface.destroy()
}

get_viewport :: proc() -> [2]i32 {
    return platform.interface.get_viewport()
}

get_viewport_f32 :: proc() -> [2]f32 {
    viewport := platform.interface.get_viewport()

    return {f32(viewport.x), f32(viewport.y)}
}

get_is_focused :: proc() -> bool {
    return platform.interface.get_is_focused()
}

get_key_state :: proc(scancode: Scancode) -> bool {
    return platform.interface.get_key_state(scancode)
}

get_mouse_position :: proc() -> [2]f32 {
    return platform.interface.get_mouse_position()
}

get_mouse_down :: proc(button: int) -> bool {
    return platform.interface.get_mouse_down(button)
}

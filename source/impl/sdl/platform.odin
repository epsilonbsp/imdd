package imdd3_impl_sdl

import sdl "vendor:sdl3"

import imdd3 "../../"

Platform :: struct {
    window: ^sdl.Window,
    viewport: [2]i32,
    is_focused: bool,
    key_state: [imdd3.Scancode]bool,
    mouse_position: [2]f32,
    mouse_down: [5]bool,
}

platform: Platform

init :: proc() {
    w, h: i32; sdl.GetWindowSize(platform.window, &w, &h)
    platform.viewport = {w, h}
    imdd3.event_resize({w = w, h = h})
}

destroy :: proc() {}

get_viewport :: proc() -> [2]i32 {
    return platform.viewport
}

get_is_focused :: proc() -> bool {
    return platform.is_focused
}

get_key_state :: proc(scancode: imdd3.Scancode) -> bool {
    return platform.key_state[scancode]
}

get_mouse_position :: proc() -> [2]f32 {
    return platform.mouse_position
}

get_mouse_down :: proc(button: int) -> bool {
    return platform.mouse_down[button]
}

process_event :: proc(event: sdl.Event) {
    #partial switch event.type {
    case .WINDOW_FOCUS_GAINED:
        platform.is_focused = true
        imdd3.event_focus_gained()
    case .WINDOW_FOCUS_LOST:
        platform.is_focused = false
        platform.key_state = {}
        imdd3.event_focus_lost()
    case .WINDOW_RESIZED:
        platform.viewport = {event.window.data1, event.window.data2}
        imdd3.event_resize({
            w = event.window.data1,
            h = event.window.data2
        })
    case .KEY_DOWN:
        scancode, ok := get_scancode(event.key.scancode)

        if ok {
            modifier := get_modifier(event.key.mod)

            platform.key_state[scancode] = true

            imdd3.event_key_down({
                scancode = scancode,
                modifier = modifier
            })
        }
    case .KEY_UP:
        scancode, ok := get_scancode(event.key.scancode)

        if ok {
            modifier := get_modifier(event.key.mod)

            platform.key_state[scancode] = false

            imdd3.event_key_up({
                scancode = scancode,
                modifier = modifier
            })
        }
    case .MOUSE_MOTION:
        platform.mouse_position = {event.motion.x, event.motion.y}

        imdd3.event_mouse_move({
            x = event.motion.x,
            y = event.motion.y,
            xrel = event.motion.xrel,
            yrel = event.motion.yrel
        })
    case .MOUSE_BUTTON_DOWN:
        modifier := get_modifier(sdl.GetModState())
        button := i32(event.button.button) - 1

        platform.mouse_down[button] = true

        imdd3.event_mouse_down({
            button = button,
            x = f32(event.button.x),
            y = f32(event.button.y),
            modifier = modifier
        })
    case .MOUSE_BUTTON_UP:
        modifier := get_modifier(sdl.GetModState())
        button := i32(event.button.button) - 1

        platform.mouse_down[button] = false

        imdd3.event_mouse_up({
            button = button,
            x = f32(event.button.x),
            y = f32(event.button.y),
            modifier = modifier
        })
    case .MOUSE_WHEEL:
        modifier := get_modifier(sdl.GetModState())

        imdd3.event_mouse_wheel({
            x = event.wheel.x,
            y = event.wheel.y,
            modifier = modifier
        })
    case .TEXT_INPUT:
        imdd3.event_text({
            text = string(event.text.text)
        })
    }
}

interface :: proc(window: ^sdl.Window) -> imdd3.Platform_Interface {
    platform.window = window

    return {
        init = init,
        destroy = destroy,

        get_viewport = get_viewport,
        get_is_focused = get_is_focused,
        get_key_state = get_key_state,
        get_mouse_position = get_mouse_position,
        get_mouse_down = get_mouse_down,
    }
}

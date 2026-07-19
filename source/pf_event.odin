package imdd3

Event_Resize :: struct {
    w: i32,
    h: i32,
}

Event_Key_Down :: struct {
    scancode: Scancode,
    modifier: Modifier,
}

Event_Key_Up :: struct {
    scancode: Scancode,
    modifier: Modifier,
}

Event_Mouse_Move :: struct {
    x: f32,
    y: f32,
    xrel: f32,
    yrel: f32,
}

Event_Mouse_Down :: struct {
    button: i32,
    x: f32,
    y: f32,
    modifier: Modifier,
}

Event_Mouse_Up :: struct {
    button: i32,
    x: f32,
    y: f32,
    modifier: Modifier,
}

Event_Mouse_Wheel :: struct {
    x: f32,
    y: f32,
    modifier: Modifier,
}

Event_Text :: struct {
    text: string,
}

event_focus_gained :: proc() {}

event_focus_lost :: proc() {}

event_resize :: proc(data: Event_Resize) {}

event_key_down :: proc(data: Event_Key_Down) {}

event_key_up :: proc(data: Event_Key_Up) {}

event_mouse_move :: proc(data: Event_Mouse_Move) {}

event_mouse_down :: proc(data: Event_Mouse_Down) {}

event_mouse_up :: proc(data: Event_Mouse_Up) {}

event_mouse_wheel :: proc(data: Event_Mouse_Wheel) {}

event_text :: proc(data: Event_Text) {}

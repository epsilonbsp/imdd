package imdd3_impl_sdl

import sdl "vendor:sdl3"

import imdd3 "../../"

get_scancode :: proc(sc: sdl.Scancode) -> (imdd3.Scancode, bool) {
    #partial switch sc {
    case .A: return .A, true
    case .B: return .B, true
    case .C: return .C, true
    case .D: return .D, true
    case .E: return .E, true
    case .F: return .F, true
    case .G: return .G, true
    case .H: return .H, true
    case .I: return .I, true
    case .J: return .J, true
    case .K: return .K, true
    case .L: return .L, true
    case .M: return .M, true
    case .N: return .N, true
    case .O: return .O, true
    case .P: return .P, true
    case .Q: return .Q, true
    case .R: return .R, true
    case .S: return .S, true
    case .T: return .T, true
    case .U: return .U, true
    case .V: return .V, true
    case .W: return .W, true
    case .X: return .X, true
    case .Y: return .Y, true
    case .Z: return .Z, true
    case ._0: return ._0, true
    case ._1: return ._1, true
    case ._2: return ._2, true
    case ._3: return ._3, true
    case ._4: return ._4, true
    case ._5: return ._5, true
    case ._6: return ._6, true
    case ._7: return ._7, true
    case ._8: return ._8, true
    case ._9: return ._9, true
    case .KP_0: return .KP_0, true
    case .KP_1: return .KP_1, true
    case .KP_2: return .KP_2, true
    case .KP_3: return .KP_3, true
    case .KP_4: return .KP_4, true
    case .KP_5: return .KP_5, true
    case .KP_6: return .KP_6, true
    case .KP_7: return .KP_7, true
    case .KP_8: return .KP_8, true
    case .KP_9: return .KP_9, true
    case .KP_ENTER: return .KP_Enter, true
    case .KP_PLUS: return .KP_Plus, true
    case .KP_MINUS: return .KP_Minus, true
    case .KP_MULTIPLY: return .KP_Multiply, true
    case .KP_DIVIDE: return .KP_Divide, true
    case .KP_PERIOD: return .KP_Period, true
    case .RETURN: return .Return, true
    case .ESCAPE: return .Escape, true
    case .BACKSPACE: return .Backspace, true
    case .TAB: return .Tab, true
    case .SPACE: return .Space, true
    case .CAPSLOCK: return .Caps_Lock, true
    case .MINUS: return .Minus, true
    case .EQUALS: return .Equals, true
    case .GRAVE: return .Grave, true
    case .LEFTBRACKET: return .Left_Bracket, true
    case .RIGHTBRACKET: return .Right_Bracket, true
    case .BACKSLASH: return .Backslash, true
    case .SEMICOLON: return .Semicolon, true
    case .APOSTROPHE: return .Apostrophe, true
    case .COMMA: return .Comma, true
    case .PERIOD: return .Period, true
    case .SLASH: return .Slash, true
    case .F1: return .F1, true
    case .F2: return .F2, true
    case .F3: return .F3, true
    case .F4: return .F4, true
    case .F5: return .F5, true
    case .F6: return .F6, true
    case .F7: return .F7, true
    case .F8: return .F8, true
    case .F9: return .F9, true
    case .F10: return .F10, true
    case .F11: return .F11, true
    case .F12: return .F12, true
    case .INSERT: return .Insert, true
    case .HOME: return .Home, true
    case .PAGEUP: return .Page_Up, true
    case .DELETE: return .Delete, true
    case .END: return .End, true
    case .PAGEDOWN: return .Page_Down, true
    case .RIGHT: return .Right, true
    case .LEFT: return .Left, true
    case .DOWN: return .Down, true
    case .UP: return .Up, true
    case .NUMLOCKCLEAR: return .Num_Lock, true
    case .PRINTSCREEN: return .Print_Screen, true
    case .SCROLLLOCK: return .Scroll_Lock, true
    case .PAUSE: return .Pause, true
    case .LCTRL: return .Left_Ctrl, true
    case .LSHIFT: return .Left_Shift, true
    case .LALT: return .Left_Alt, true
    case .RCTRL: return .Right_Ctrl, true
    case .RSHIFT: return .Right_Shift, true
    case .RALT: return .Right_Alt, true
    }

    return {}, false
}

get_modifier :: proc(mods: sdl.Keymod) -> imdd3.Modifier {
    return {
        alt = .LALT in mods || .RALT in mods,
        ctrl = .LCTRL in mods || .RCTRL in mods,
        shift = .LSHIFT in mods || .RSHIFT in mods,
    }
}

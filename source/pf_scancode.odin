package imdd3

Scancode :: enum i32 {
    // Letters
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,

    // Digits
    _0,
    _1,
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,

    // Numpad
    KP_0,
    KP_1,
    KP_2,
    KP_3,
    KP_4,
    KP_5,
    KP_6,
    KP_7,
    KP_8,
    KP_9,
    KP_Enter,
    KP_Plus,
    KP_Minus,
    KP_Multiply,
    KP_Divide,
    KP_Period,

    // Special
    Return,
    Escape,
    Backspace,
    Tab,
    Space,
    Caps_Lock,

    // Punctuation
    Minus,
    Equals,
    Grave,
    Left_Bracket,
    Right_Bracket,
    Backslash,
    Semicolon,
    Apostrophe,
    Comma,
    Period,
    Slash,

    // Function keys
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,

    // Navigation
    Insert,
    Home,
    Page_Up,
    Delete,
    End,
    Page_Down,
    Right,
    Left,
    Down,
    Up,
    Num_Lock,
    Print_Screen,
    Scroll_Lock,
    Pause,

    // Modifiers
    Left_Ctrl,
    Left_Shift,
    Left_Alt,
    Right_Ctrl,
    Right_Shift,
    Right_Alt,
}

Modifier :: struct {
    alt: bool,
    ctrl: bool,
    shift: bool,
}

scancode_name :: proc(key: i32) -> string {
    #partial switch Scancode(key) {
    case .A: return "A"
    case .B: return "B"
    case .C: return "C"
    case .D: return "D"
    case .E: return "E"
    case .F: return "F"
    case .G: return "G"
    case .H: return "H"
    case .I: return "I"
    case .J: return "J"
    case .K: return "K"
    case .L: return "L"
    case .M: return "M"
    case .N: return "N"
    case .O: return "O"
    case .P: return "P"
    case .Q: return "Q"
    case .R: return "R"
    case .S: return "S"
    case .T: return "T"
    case .U: return "U"
    case .V: return "V"
    case .W: return "W"
    case .X: return "X"
    case .Y: return "Y"
    case .Z: return "Z"
    case ._0: return "0"
    case ._1: return "1"
    case ._2: return "2"
    case ._3: return "3"
    case ._4: return "4"
    case ._5: return "5"
    case ._6: return "6"
    case ._7: return "7"
    case ._8: return "8"
    case ._9: return "9"
    case .KP_0: return "KP 0"
    case .KP_1: return "KP 1"
    case .KP_2: return "KP 2"
    case .KP_3: return "KP 3"
    case .KP_4: return "KP 4"
    case .KP_5: return "KP 5"
    case .KP_6: return "KP 6"
    case .KP_7: return "KP 7"
    case .KP_8: return "KP 8"
    case .KP_9: return "KP 9"
    case .KP_Enter: return "KP Enter"
    case .KP_Plus: return "KP +"
    case .KP_Minus: return "KP -"
    case .KP_Multiply: return "KP *"
    case .KP_Divide: return "KP /"
    case .KP_Period: return "KP ."
    case .Return: return "Enter"
    case .Escape: return "Escape"
    case .Backspace: return "Backspace"
    case .Tab: return "Tab"
    case .Space: return "Space"
    case .Caps_Lock: return "Caps Lock"
    case .Minus: return "-"
    case .Equals: return "="
    case .Grave: return "`"
    case .Left_Bracket: return "["
    case .Right_Bracket: return "]"
    case .Backslash: return "\\"
    case .Semicolon: return ";"
    case .Apostrophe: return "'"
    case .Comma: return ","
    case .Period: return "."
    case .Slash: return "/"
    case .F1: return "F1"
    case .F2: return "F2"
    case .F3: return "F3"
    case .F4: return "F4"
    case .F5: return "F5"
    case .F6: return "F6"
    case .F7: return "F7"
    case .F8: return "F8"
    case .F9: return "F9"
    case .F10: return "F10"
    case .F11: return "F11"
    case .F12: return "F12"
    case .Insert: return "Insert"
    case .Home: return "Home"
    case .Page_Up: return "Page Up"
    case .Delete: return "Delete"
    case .End: return "End"
    case .Page_Down: return "Page Down"
    case .Right: return "Right"
    case .Left: return "Left"
    case .Down: return "Down"
    case .Up: return "Up"
    case .Num_Lock: return "Num Lock"
    case .Print_Screen: return "Print Screen"
    case .Scroll_Lock: return "Scroll Lock"
    case .Pause: return "Pause"
    case .Left_Ctrl: return "Ctrl"
    case .Left_Shift: return "Shift"
    case .Left_Alt: return "Alt"
    case .Right_Ctrl: return "Right Ctrl"
    case .Right_Shift: return "Right Shift"
    case .Right_Alt: return "Right Alt"
    }

    return "?"
}

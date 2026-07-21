package imdd3

Resources :: struct {
    atlas: []u8,
    fonts_regular: []u8,
    fonts_italic: []u8,
    fonts_bold: []u8,
    icons: []u8,
}

resources: Resources

init_resources :: proc(custom_resources: Resources = {}) {
    resources = custom_resources

    if len(resources.atlas) == 0 {
        resources.atlas = #load("../assets/atlas/atlas.png")
    }

    if len(resources.fonts_regular) == 0 {
        resources.fonts_regular = #load("../assets/atlas/fonts/regular.json")
    }

    if len(resources.fonts_italic) == 0 {
        resources.fonts_italic = #load("../assets/atlas/fonts/italic.json")
    }

    if len(resources.fonts_bold) == 0 {
        resources.fonts_bold = #load("../assets/atlas/fonts/bold.json")
    }

    if len(resources.icons) == 0 {
        resources.icons = #load("../assets/atlas/icons/icons.json")
    }
}

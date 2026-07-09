package imdd3

import "core:encoding/json"

Icon :: struct {
    px_size: f32,
    uv_left: f32,
    uv_right: f32,
    uv_top: f32,
    uv_bottom: f32,
}

Icons :: struct {
    distance_range: f32,
    icons: map[string]Icon,
}

Icons_Atlas_Json :: struct {
    width: f32,
    height: f32,
    distanceRange: f32,
}

Icon_Json :: struct {
    key: string,
    x: f32,
    y: f32,
    w: f32,
    h: f32,
}

Icons_Json :: struct {
    atlas: Icons_Atlas_Json,
    icons: []Icon_Json,
}

load_icons :: proc() {
    data := #load("../assets/atlas/icons/icons.json")

    icons_json: Icons_Json
    error := json.unmarshal(data, &icons_json)
    assert(error == nil, "ERROR: Failed to parse icons.json")
    defer delete(icons_json.icons)

    atlas_width := icons_json.atlas.width
    atlas_height := icons_json.atlas.height

    state.icons.distance_range = icons_json.atlas.distanceRange
    state.icons.icons = make(map[string]Icon)

    for icon_json in icons_json.icons {
        icon: Icon
        icon.px_size = min(icon_json.w, icon_json.h)
        icon.uv_left = icon_json.x / atlas_width
        icon.uv_right = (icon_json.x + icon_json.w) / atlas_width
        icon.uv_top = icon_json.y / atlas_height
        icon.uv_bottom = (icon_json.y + icon_json.h) / atlas_height

        state.icons.icons[icon_json.key] = icon
    }
}

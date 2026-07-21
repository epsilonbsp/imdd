package imdd3

import "core:encoding/json"

Glyph :: struct {
    advance: f32,

    // Quad bounds relative to baseline in em units
    plane_left: f32,
    plane_right: f32,
    plane_top: f32,
    plane_bottom: f32,

    // UV coords in font atlas
    uv_left: f32,
    uv_right: f32,
    uv_top: f32,
    uv_bottom: f32,

    has_geometry: bool,
}

Font :: struct {
    glyphs: [128]Glyph,
    distance_range: f32,
    em_size: f32,
    line_height: f32,
    ascender: f32,
}

Font_Weight :: enum int {
    REGULAR,
    ITALIC,
    BOLD,
}

Atlas_Json :: struct {
    width: f32,
    height: f32,
    distanceRange: f32,
    size: f32,
}

Metrics_Json :: struct {
    lineHeight: f32,
    ascender: f32,
}

Bounds_Json :: struct {
    left: f32,
    bottom: f32,
    right: f32,
    top: f32,
}

Glyph_Json :: struct {
    unicode: int,
    advance: f32,
    planeBounds: Bounds_Json,
    atlasBounds: Bounds_Json,
}

Font_Json :: struct {
    atlas: Atlas_Json,
    metrics: Metrics_Json,
    glyphs: []Glyph_Json,
}

load_font :: proc(data: []u8) -> Font {
    font_json: Font_Json
    error := json.unmarshal(data, &font_json)
    assert(error == nil, "ERROR: Failed to parse state.font.json")
    defer delete(font_json.glyphs)

    atlas_width := font_json.atlas.width
    atlas_height := font_json.atlas.height

    font: Font
    font.distance_range = font_json.atlas.distanceRange
    font.em_size = font_json.atlas.size
    font.line_height = font_json.metrics.lineHeight
    font.ascender = font_json.metrics.ascender

    for glyph_json in font_json.glyphs {
        if glyph_json.unicode < 32 || glyph_json.unicode > 126 {
            continue
        }

        glyph := &font.glyphs[glyph_json.unicode - 32]
        glyph.advance = glyph_json.advance

        if glyph_json.atlasBounds.right > 0 {
            glyph.plane_left = glyph_json.planeBounds.left
            glyph.plane_right = glyph_json.planeBounds.right
            glyph.plane_top = glyph_json.planeBounds.top
            glyph.plane_bottom = glyph_json.planeBounds.bottom

            glyph.uv_left = glyph_json.atlasBounds.left / atlas_width
            glyph.uv_right = glyph_json.atlasBounds.right / atlas_width
            glyph.uv_top = 1.0 - glyph_json.atlasBounds.top / atlas_height
            glyph.uv_bottom = 1.0 - glyph_json.atlasBounds.bottom / atlas_height

            glyph.has_geometry = true
        }
    }

    return font
}

load_fonts :: proc() {
    renderer.fonts[.REGULAR] = load_font(resources.fonts_regular)
    renderer.fonts[.ITALIC] = load_font(resources.fonts_italic)
    renderer.fonts[.BOLD] = load_font(resources.fonts_bold)
}

font_weight :: proc(font_weight: Font_Weight) {
    renderer.font_weight = font_weight
}

package imdd3

import glm "core:math/linalg/glsl"

TRIANGLE_VERTEX_CAP :: 16384
TRIANGLE_INDEX_CAP :: TRIANGLE_VERTEX_CAP * 3 / 2

Triangle_Vertex :: struct {
    mode: u32,
    position: [3]f32,
    tex_coord: [2]f32,
    tex_index: u32,
    colors: [2]u32,
    params: [4]f32,
}

Triangle_State :: struct {
    vertices: [dynamic]Triangle_Vertex,
    indices: [dynamic]u32,
}

triangle_state: Triangle_State

triangle_init :: proc() {
    triangle_state.vertices = make([dynamic]Triangle_Vertex, 0, TRIANGLE_VERTEX_CAP)
    triangle_state.indices = make([dynamic]u32, 0, TRIANGLE_INDEX_CAP)
}

triangle_destroy :: proc() {
    delete(triangle_state.vertices)
    delete(triangle_state.indices)
}

triangle_render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    renderer.interface.triangle_render(triangle_state.vertices[:], triangle_state.indices[:], projection, view)

    clear(&triangle_state.vertices)
    clear(&triangle_state.indices)
}

point :: proc(pos: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))

    a := pos - tangent * radius - bitangent * radius
    b := pos + tangent * radius - bitangent * radius
    c := pos + tangent * radius + bitangent * radius
    d := pos - tangent * radius + bitangent * radius

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{1, a, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{2, b, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{3, c, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{4, d, {}, 0, {color, 0}, {radius, radius, radius, 0}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

line :: proc(a: [3]f32, b: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32) {
    diff := b - a
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    perp := glm.normalize(glm.cross(normal, dir)) * (width * 0.5)

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, a - perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, b - perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, b + perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, a + perp, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

arrow :: proc(a: [3]f32, b: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, head_size: f32, color: u32) {
    diff := b - a
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    body_end := b - dir * head_size
    body_perp := glm.normalize(glm.cross(normal, dir)) * (width * 0.5)
    head_perp := glm.normalize(glm.cross(normal, dir)) * (head_size * 0.5)

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, a - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, a + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, b, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end + head_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end - head_perp, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3,
        l + 4, l + 5, l + 6
    )
}

triangle :: proc(a: [3]f32, b: [3]f32, c: [3]f32, color: u32) {
    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, a, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, b, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, c, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2
    )
}

rect :: proc(pos: [3]f32, size: [2]f32, color: u32) {
    hs := size / 2
    a := pos + {-hs.x, -hs.y, pos.z}
    b := pos + {hs.x, -hs.y, pos.z}
    c := pos + {hs.x, hs.y, pos.z}
    d := pos + {-hs.x, hs.y, pos.z}

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, a, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, b, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, c, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, d, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

// rect_rounded :: proc(pos: [2]f32, size: [2]f32, color: u32, radius: f32 = 0) {
//     hs := size / 2
//     a := pos + {-hs.x, -hs.y}
//     b := pos + {hs.x, -hs.y}
//     c := pos + {hs.x, hs.y}
//     d := pos + {-hs.x, hs.y}

//     l := u32(len(triangle_state.vertices))

//     append(
//         &triangle_state.vertices,
//         Triangle_Vertex{1, a, {}, 0, {color, 0}, {hs.x, hs.y, radius, 0}},
//         Triangle_Vertex{2, b, {}, 0, {color, 0}, {hs.x, hs.y, radius, 0}},
//         Triangle_Vertex{3, c, {}, 0, {color, 0}, {hs.x, hs.y, radius, 0}},
//         Triangle_Vertex{4, d, {}, 0, {color, 0}, {hs.x, hs.y, radius, 0}}
//     )

//     append(
//         &triangle_state.indices,
//         l, l + 1, l + 2,
//         l, l + 2, l + 3
//     )
// }

// circle :: proc(pos: [2]f32, radius: f32, color: u32) {
//     a := pos + {-radius, -radius}
//     b := pos + {radius, -radius}
//     c := pos + {radius, radius}
//     d := pos + {-radius, radius}

//     l := u32(len(triangle_state.vertices))

//     append(
//         &triangle_state.vertices,
//         Triangle_Vertex{1, a, {}, 0, {color, 0}, {radius, radius, radius, 0}},
//         Triangle_Vertex{2, b, {}, 0, {color, 0}, {radius, radius, radius, 0}},
//         Triangle_Vertex{3, c, {}, 0, {color, 0}, {radius, radius, radius, 0}},
//         Triangle_Vertex{4, d, {}, 0, {color, 0}, {radius, radius, radius, 0}}
//     )

//     append(
//         &triangle_state.indices,
//         l, l + 1, l + 2,
//         l, l + 2, l + 3
//     )
// }

// box :: proc(pos: [2]f32, size: [2]f32, fill_color: u32, radius: f32 = 0, stroke_width: f32 = 0, stroke_color: u32) {
//     hs := size / 2
//     a := pos + {-hs.x, -hs.y}
//     b := pos + {hs.x, -hs.y}
//     c := pos + {hs.x, hs.y}
//     d := pos + {-hs.x, hs.y}

//     l := u32(len(triangle_state.vertices))

//     append(
//         &triangle_state.vertices,
//         Triangle_Vertex{1, a, {}, 0, {fill_color, stroke_color}, {hs.x, hs.y, radius, stroke_width}},
//         Triangle_Vertex{2, b, {}, 0, {fill_color, stroke_color}, {hs.x, hs.y, radius, stroke_width}},
//         Triangle_Vertex{3, c, {}, 0, {fill_color, stroke_color}, {hs.x, hs.y, radius, stroke_width}},
//         Triangle_Vertex{4, d, {}, 0, {fill_color, stroke_color}, {hs.x, hs.y, radius, stroke_width}}
//     )

//     append(
//         &triangle_state.indices,
//         l, l + 1, l + 2,
//         l, l + 2, l + 3
//     )
// }

// box_circle :: proc(pos: [2]f32, radius: f32, fill_color: u32, stroke_width: f32 = 0, stroke_color: u32) {
//     box(pos, {radius * 2, radius * 2}, fill_color, radius, stroke_width, stroke_color)
// }

// rect_outline :: proc(pos: [2]f32, size: [2]f32, stroke_width: f32 = 0, stroke_color: u32) {
//     box(pos, size, 0, 0, stroke_width, stroke_color)
// }

// rect_rounded_outline :: proc(pos: [2]f32, size: [2]f32, radius: f32 = 0, stroke_width: f32 = 0, stroke_color: u32) {
//     box(pos, size, 0, radius, stroke_width, stroke_color)
// }

// circle_outline :: proc(pos: [2]f32, radius: f32, stroke_width: f32 = 0, stroke_color: u32) {
//     box(pos, {radius * 2, radius * 2}, 0, radius, stroke_width, stroke_color)
// }

text :: proc(pos: [3]f32, normal: [3]f32, tangent: [3]f32, text: string, font_size: f32, line_height: f32, color: u32, clip_max_x: f32 = max(f32)) {
    font := &renderer.fonts[renderer.font_weight]

    x := pos.x
    baseline_y := pos.y + (line_height - font.line_height * font_size) / 2 + (font.line_height - font.ascender) * font_size
    px_range := font.distance_range * (font_size / font.em_size)

    bitangent := glm.normalize(glm.cross(tangent, normal))

    for ch in text {
        idx := int(ch) - 32

        if idx < 0 || idx >= len(font.glyphs) {
            continue
        }

        g := font.glyphs[idx]

        if x + g.advance * font_size > clip_max_x {
            break
        }

        if g.has_geometry {
            quad_left := x + g.plane_left * font_size
            quad_right := x + g.plane_right * font_size
            quad_top := baseline_y + g.plane_top * font_size
            quad_bottom := baseline_y + g.plane_bottom * font_size

            a := pos + tangent * quad_left + bitangent * quad_bottom
            b := pos + tangent * quad_right + bitangent * quad_bottom
            c := pos + tangent * quad_right + bitangent * quad_top
            d := pos + tangent * quad_left + bitangent * quad_top

            l := u32(len(triangle_state.vertices))

            append(
                &triangle_state.vertices,
                Triangle_Vertex{5, a, {g.uv_left,  g.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{5, b, {g.uv_right, g.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{5, c, {g.uv_right, g.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{5, d, {g.uv_left,  g.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}}
            )

            append(
                &triangle_state.indices,
                l, l + 1, l + 2,
                l, l + 2, l + 3
            )
        }

        x += g.advance * font_size
    }
}

icon :: proc(pos: [3]f32, size: f32, key: string, color: u32) {
    ic, ok := renderer.icons.icons[key]

    if !ok {
        return
    }

    hs := size / 2
    a := pos + {-hs, -hs, pos.z}
    b := pos + {hs, -hs, pos.z}
    c := pos + {hs, hs, pos.z}
    d := pos + {-hs, hs, pos.z}

    px_range := renderer.icons.distance_range * (size / ic.px_size)

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{5, a, {ic.uv_left, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, b, {ic.uv_right, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, c, {ic.uv_right, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, d, {ic.uv_left, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

image :: proc(pos: [3]f32, size: [2]f32, sprite: Sprite) {
    hs := size / 2
    a := pos + {-hs.x, -hs.y, pos.z}
    b := pos + {hs.x, -hs.y, pos.z}
    c := pos + {hs.x, hs.y, pos.z}
    d := pos + {-hs.x, hs.y, pos.z}

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

image_rounded :: proc(pos: [3]f32, size: [2]f32, sprite: Sprite, radius: f32 = 0) {
    hs := size / 2
    a := pos + {-hs.x, -hs.y, pos.z}
    b := pos + {hs.x, -hs.y, pos.z}
    c := pos + {hs.x, hs.y, pos.z}
    d := pos + {-hs.x, hs.y, pos.z}

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{1, a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {hs.x, hs.y, radius, 0}},
        Triangle_Vertex{2, b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {hs.x, hs.y, radius, 0}},
        Triangle_Vertex{3, c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {hs.x, hs.y, radius, 0}},
        Triangle_Vertex{4, d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {hs.x, hs.y, radius, 0}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

grid :: proc(pos: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    hs := size / 2
    bitangent := glm.normalize(glm.cross(normal, tangent))

    a := pos - tangent * hs.x - bitangent * hs.y
    b := pos + tangent * hs.x - bitangent * hs.y
    c := pos + tangent * hs.x + bitangent * hs.y
    d := pos - tangent * hs.x + bitangent * hs.y

    l := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{6, a, {-hs.x, -hs.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, b, { hs.x, -hs.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, c, { hs.x, hs.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, d, {-hs.x, hs.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}}
    )

    append(
        &triangle_state.indices,
        l, l + 1, l + 2,
        l, l + 2, l + 3
    )
}

grid_xy :: proc(pos: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    grid(pos, {0, 0, -1}, {1, 0, 0}, size, cell_size, line_width, color)
}

grid_xz :: proc(pos: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    grid(pos, {0, 1, 0}, {1, 0, 0}, size, cell_size, line_width, color)
}

grid_yz :: proc(pos: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    grid(pos, {1, 0, 0}, {0, 1, 0}, size, cell_size, line_width, color)
}

frustum :: proc(proj_view: matrix[4, 4]f32, normal: [3]f32, tangent: [3]f32, line_width: f32, color: u32) {
    inv_proj_view := glm.inverse(proj_view)

    corners: [8][3]f32

    ndc := [8][4]f32{
        {-1, -1, -1, 1},
        { 1, -1, -1, 1},
        { 1,  1, -1, 1},
        {-1,  1, -1, 1},
        {-1, -1,  1, 1},
        { 1, -1,  1, 1},
        { 1,  1,  1, 1},
        {-1,  1,  1, 1},
    }

    for i in 0 ..< 8 {
        p := inv_proj_view * ndc[i]
        p /= p.w
        corners[i] = p.xyz
    }

    line(corners[0], corners[1], normal, tangent, line_width, color)
    line(corners[1], corners[2], normal, tangent, line_width, color)
    line(corners[2], corners[3], normal, tangent, line_width, color)
    line(corners[3], corners[0], normal, tangent, line_width, color)

    // Far plane
    line(corners[4], corners[5], normal, tangent, line_width, color)
    line(corners[5], corners[6], normal, tangent, line_width, color)
    line(corners[6], corners[7], normal, tangent, line_width, color)
    line(corners[7], corners[4], normal, tangent, line_width, color)

    // Sides
    line(corners[0], corners[4], normal, tangent, line_width, color)
    line(corners[1], corners[5], normal, tangent, line_width, color)
    line(corners[2], corners[6], normal, tangent, line_width, color)
    line(corners[3], corners[7], normal, tangent, line_width, color)
}

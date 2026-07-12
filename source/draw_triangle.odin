package imdd3

import glm "core:math/linalg/glsl"

TRIANGLE_VERTEX_CAP :: 16384
TRIANGLE_INDEX_CAP :: TRIANGLE_VERTEX_CAP * 3 / 2

Stroke_Join_Type :: enum {
    None,
    Bevel,
    Miter,
    Round,
}

Stroke_Cap_Type :: enum {
    None,
    Square,
    Triangle,
    Round,
}

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

triangle_render :: proc() {
    renderer.interface.triangle_render(triangle_state.vertices[:], triangle_state.indices[:])

    clear(&triangle_state.vertices)
    clear(&triangle_state.indices)
}

// API
draw_triangle :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, color: u32) {
    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, point0, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point1, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point2, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2
    )
}

draw_rect :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size * 0.5

    point_a := center - tangent * extent.x - bitangent * extent.y
    point_b := center + tangent * extent.x - bitangent * extent.y
    point_c := center + tangent * extent.x + bitangent * extent.y
    point_d := center - tangent * extent.x + bitangent * extent.y

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, point_a, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point_b, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point_c, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point_d, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_circle :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))

    point_a := center - tangent * radius - bitangent * radius
    point_b := center + tangent * radius - bitangent * radius
    point_c := center + tangent * radius + bitangent * radius
    point_d := center - tangent * radius + bitangent * radius

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{1, point_a, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{2, point_b, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{3, point_c, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{4, point_d, {}, 0, {color, 0}, {radius, radius, radius, 0}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_rrect :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, fill_color: u32, radius: f32 = 0, stroke_width: f32 = 0, stroke_color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    point_a := center - tangent * extent.x - bitangent * extent.y
    point_b := center + tangent * extent.x - bitangent * extent.y
    point_c := center + tangent * extent.x + bitangent * extent.y
    point_d := center - tangent * extent.x + bitangent * extent.y

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{1, point_a, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{2, point_b, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{3, point_c, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{4, point_d, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_stroke :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32) {
    diff := point1 - point0
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    perp := glm.normalize(glm.cross(normal, dir)) * (width * 0.5)

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, point0 - perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point1 - perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point1 + perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point0 + perp, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_stroke_join :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, type: Stroke_Join_Type, miter_limit: f32 = 4) {
    if type == .None {
        return
    }

    dir_in := glm.normalize(point1 - point0)
    dir_out := glm.normalize(point2 - point1)

    perp_in := glm.normalize(glm.cross(normal, dir_in))
    perp_out := glm.normalize(glm.cross(normal, dir_out))

    sigma: f32 = glm.dot(dir_in, perp_out) >= 0 ? 1 : -1

    radius := width * 0.5

    point_in := point1 + perp_in * radius * sigma
    point_out := point1 + perp_out * radius * sigma

    #partial switch type {
    case .Bevel:
        draw_triangle(point1, point_in, point_out, color)
    case .Miter:
        miter_dir := glm.normalize(dir_in - dir_out)
        denom := glm.dot(miter_dir, perp_in)

        if abs(denom) < 0.0001 || abs(1 / denom) > miter_limit {
            draw_triangle(point1, point_in, point_out, color)

            return
        }

        miter_length := radius / denom
        miter := point1 + miter_dir * miter_length * sigma

        draw_triangle(point1, point_in, miter, color)
        draw_triangle(point1, miter, point_out, color)
    case .Round:
        draw_circle(point1, normal, tangent, radius, color)
    }
}

draw_stroke_cap :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, type: Stroke_Cap_Type) {
    if type == .None {
        return
    }

    dir := glm.normalize(point1 - point0)
    radius := width * 0.5

    #partial switch type {
    case .Square:
        draw_stroke(point1, point1 + dir * radius, normal, tangent, width, color)
    case .Triangle:
        perp := glm.normalize(glm.cross(normal, dir)) * radius
        tip := point1 + dir * radius

        draw_triangle(point1 - perp, point1 + perp, tip, color)
    case .Round:
        draw_circle(point1, normal, tangent, radius, color)
    }
}

draw_stroke_arrow :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, head_size: f32, color: u32) {
    diff := point1 - point0
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    body_end := point1 - dir * head_size
    body_perp := glm.normalize(glm.cross(normal, dir)) * (width * 0.5)
    head_perp := glm.normalize(glm.cross(normal, dir)) * (head_size * 0.5)

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, point0 - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point0 + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, point1, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end + head_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{0, body_end - head_perp, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3,
        index + 4, index + 5, index + 6
    )
}

draw_grid :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    point_a := center - tangent * extent.x - bitangent * extent.y
    point_b := center + tangent * extent.x - bitangent * extent.y
    point_c := center + tangent * extent.x + bitangent * extent.y
    point_d := center - tangent * extent.x + bitangent * extent.y

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{6, point_a, {-extent.x, -extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, point_b, { extent.x, -extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, point_c, { extent.x, extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{6, point_d, {-extent.x, extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_grid_xy :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {0, 0, -1}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_grid_xz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {0, 1, 0}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_grid_yz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {1, 0, 0}, {0, 1, 0}, size, cell_size, line_width, color)
}

draw_text :: proc(position: [3]f32, normal: [3]f32, tangent: [3]f32, text: string, font_size: f32, line_height: f32, color: u32, clip_max_x: f32 = max(f32)) {
    bitangent := glm.normalize(glm.cross(tangent, normal))
    x := position.x

    font := &renderer.fonts[renderer.font_weight]
    baseline_y := position.y + (line_height - font.line_height * font_size) / 2 + (font.line_height - font.ascender) * font_size
    px_range := font.distance_range * (font_size / font.em_size)

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

            a := position + tangent * quad_left + bitangent * quad_bottom
            b := position + tangent * quad_right + bitangent * quad_bottom
            c := position + tangent * quad_right + bitangent * quad_top
            d := position + tangent * quad_left + bitangent * quad_top

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

draw_icon :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: f32, key: string, color: u32) {
    ic, ok := renderer.icons.icons[key]

    if !ok {
        return
    }

    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    point_a := center - tangent * extent - bitangent * extent
    point_b := center + tangent * extent - bitangent * extent
    point_c := center + tangent * extent + bitangent * extent
    point_d := center - tangent * extent + bitangent * extent

    px_range := renderer.icons.distance_range * (size / ic.px_size)

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{5, point_a, {ic.uv_left, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, point_b, {ic.uv_right, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, point_c, {ic.uv_right, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{5, point_d, {ic.uv_left, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_image :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, sprite: Sprite) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    point_a := center - tangent * extent.x - bitangent * extent.y
    point_b := center + tangent * extent.x - bitangent * extent.y
    point_c := center + tangent * extent.x + bitangent * extent.y
    point_d := center - tangent * extent.x + bitangent * extent.y

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{0, point_a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, point_b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, point_c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{0, point_d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_rimage:: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, sprite: Sprite, radius: f32 = 0) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    point_a := center - tangent * extent.x - bitangent * extent.y
    point_b := center + tangent * extent.x - bitangent * extent.y
    point_c := center + tangent * extent.x + bitangent * extent.y
    point_d := center - tangent * extent.x + bitangent * extent.y

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{1, point_a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{2, point_b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{3, point_c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{4, point_d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

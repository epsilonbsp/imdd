package imdd3

import glm "core:math/linalg/glsl"

TRIANGLE_VERTEX_CAP :: 16384
TRIANGLE_INDEX_CAP :: TRIANGLE_VERTEX_CAP * 3 / 2

Triangle_Mode :: enum u32 {
    Default,
    SDF_0,
    SDF_1,
    SDF_2,
    SDF_3,
    Stroke,
    Grid,
    Text,
}

Stroke_Join_Type :: enum {
    None,
    Miter,
    Bevel,
    Round,
}

Stroke_Cap_Type :: enum {
    None,
    Square,
    Triangle,
    Round,
}

TEXT_LEFT :: -1
TEXT_CENTER :: 0
TEXT_RIGHT :: 1
TEXT_BOTTOM :: -1
TEXT_MIDDLE :: 0
TEXT_TOP :: 1

Triangle_Vertex :: struct {
    mode: Triangle_Mode,
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
        Triangle_Vertex{.Default, point0, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point1, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point2, {}, 0, {color, 0}, {}}
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
        Triangle_Vertex{.Default, point_a, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point_b, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point_c, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point_d, {}, 0, {color, 0}, {}}
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
        Triangle_Vertex{.SDF_0, point_a, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{.SDF_1, point_b, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{.SDF_2, point_c, {}, 0, {color, 0}, {radius, radius, radius, 0}},
        Triangle_Vertex{.SDF_3, point_d, {}, 0, {color, 0}, {radius, radius, radius, 0}}
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
        Triangle_Vertex{.SDF_0, point_a, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{.SDF_1, point_b, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{.SDF_2, point_c, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}},
        Triangle_Vertex{.SDF_3, point_d, {}, 0, {fill_color, stroke_color}, {extent.x, extent.y, radius, stroke_width}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_stroke :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, dash: [2]f32 = {}) {
    diff := point1 - point0
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    perp := glm.normalize(glm.cross(normal, dir)) * (width * 0.5)

    distance := dash[0] + length

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{.Stroke, point0 - perp, {}, 0, {color, 0}, {dash[0], dash[1], 0, 0}},
        Triangle_Vertex{.Stroke, point1 - perp, {}, 0, {color, 0}, {distance, dash[1], 0, 0}},
        Triangle_Vertex{.Stroke, point1 + perp, {}, 0, {color, 0}, {distance, dash[1], 0, 0}},
        Triangle_Vertex{.Stroke, point0 + perp, {}, 0, {color, 0}, {dash[0], dash[1], 0, 0}}
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
    case .Bevel:
        draw_triangle(point1, point_in, point_out, color)
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
    cap_start := point1
    cap_end := cap_start + dir * radius

    #partial switch type {
    case .Square:
        draw_stroke(cap_start, cap_end, normal, tangent, width, color)
    case .Triangle:
        perp := glm.normalize(glm.cross(normal, dir)) * radius

        draw_triangle(cap_start - perp, cap_start + perp, cap_end, color)
    case .Round:
        draw_circle(cap_start, normal, tangent, radius, color)
    }
}

draw_stroke_strip :: proc(points: [][3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, dash: f32 = 0, is_looped := false, join_type: Stroke_Join_Type = .None, cap_type: Stroke_Cap_Type = .None) {
    if len(points) < 2 {
        return
    }

    count := len(points)
    segment_count := is_looped ? count : count - 1

    if !is_looped {
        draw_stroke_cap(points[1], points[0], normal, tangent, width, color, cap_type)
    }

    total_distance: f32 = 0

    for i in 0 ..< segment_count {
        curr := points[i]
        next := points[(i + 1) % count]

        draw_stroke(curr, next, normal, tangent, width, color, {total_distance, dash})
        total_distance += glm.distance(curr, next)

        if is_looped || i < segment_count - 1 {
            join_next := points[(i + 2) % count]

            draw_stroke_join(curr, next, join_next, normal, tangent, width, color, join_type)
        }
    }

    if !is_looped {
        draw_stroke_cap(points[count - 2], points[count - 1], normal, tangent, width, color, cap_type)
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
        Triangle_Vertex{.Default, point0 - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, body_end - body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, body_end + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point0 + body_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, point1, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, body_end + head_perp, {}, 0, {color, 0}, {}},
        Triangle_Vertex{.Default, body_end - head_perp, {}, 0, {color, 0}, {}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3,
        index + 4, index + 5, index + 6
    )
}

draw_stroke_grid :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    extent := size / 2

    for x := -extent.x; x <= extent.x + 0.001; x += cell_size.x {
        point0 := center + tangent * x - bitangent * extent.y
        point1 := center + tangent * x + bitangent * extent.y

        draw_stroke(point0, point1, normal, tangent, line_width, color)
    }

    for y := -extent.y; y <= extent.y + 0.001; y += cell_size.y {
        point0 := center - tangent * extent.x + bitangent * y
        point1 := center + tangent * extent.x + bitangent * y

        draw_stroke(point0, point1, normal, tangent, line_width, color)
    }
}

draw_stroke_grid_xy :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_stroke_grid(center, {0, 0, 1}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_stroke_grid_xz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_stroke_grid(center, {0, 1, 0}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_stroke_grid_yz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_stroke_grid(center, {1, 0, 0}, {0, 1, 0}, size, cell_size, line_width, color)
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
        Triangle_Vertex{.Grid, point_a, {-extent.x, -extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{.Grid, point_b, { extent.x, -extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{.Grid, point_c, { extent.x, extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}},
        Triangle_Vertex{.Grid, point_d, {-extent.x, extent.y}, 0, {color, 0}, {cell_size.x, cell_size.y, line_width, 0}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

draw_grid_xy :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {0, 0, 1}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_grid_xz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {0, 1, 0}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_grid_yz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_grid(center, {1, 0, 0}, {0, 1, 0}, size, cell_size, line_width, color)
}

draw_text :: proc(position: [3]f32, normal: [3]f32, tangent: [3]f32, text: string, font_size: f32, line_height: f32, color: u32, alignment: [2]f32 = {}, clip_max_x: f32 = max(f32)) {
    bitangent := glm.normalize(glm.cross(normal, tangent))

    font := &renderer.fonts[renderer.font_weight]
    px_range := font.distance_range

    x := position.x

    if alignment.x != -1 {
        width: f32 = 0

        for ch in text {
            idx := int(ch) - 32

            if idx < 0 || idx >= len(font.glyphs) {
                continue
            }

            width += font.glyphs[idx].advance * font_size
        }

        x -= width * 0.5 * (alignment.x + 1)
    }

    baseline_y := position.y + font_size * (font.line_height * 0.5 - font.ascender) - line_height * alignment.y * 0.5

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

            point_a := position + tangent * quad_left + bitangent * quad_bottom
            point_b := position + tangent * quad_right + bitangent * quad_bottom
            point_c := position + tangent * quad_right + bitangent * quad_top
            point_d := position + tangent * quad_left + bitangent * quad_top

            index := u32(len(triangle_state.vertices))

            append(
                &triangle_state.vertices,
                Triangle_Vertex{.Text, point_a, {g.uv_left,  g.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{.Text, point_b, {g.uv_right, g.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{.Text, point_c, {g.uv_right, g.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
                Triangle_Vertex{.Text, point_d, {g.uv_left,  g.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}}
            )

            append(
                &triangle_state.indices,
                index, index + 1, index + 2,
                index, index + 2, index + 3
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

    px_range := renderer.icons.distance_range

    index := u32(len(triangle_state.vertices))

    append(
        &triangle_state.vertices,
        Triangle_Vertex{.Text, point_a, {ic.uv_left, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{.Text, point_b, {ic.uv_right, ic.uv_bottom}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{.Text, point_c, {ic.uv_right, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
        Triangle_Vertex{.Text, point_d, {ic.uv_left, ic.uv_top}, 0, {color, 0}, {px_range, 0, 0, 0}},
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
        Triangle_Vertex{.Default, point_a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{.Default, point_b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{.Default, point_c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {}},
        Triangle_Vertex{.Default, point_d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {}}
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
        Triangle_Vertex{.SDF_0, point_a, {sprite.left, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{.SDF_1, point_b, {sprite.right, sprite.bottom}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{.SDF_2, point_c, {sprite.right, sprite.top}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}},
        Triangle_Vertex{.SDF_3, point_d, {sprite.left, sprite.top}, sprite.handle, {0xffffffff, 0}, {extent.x, extent.y, radius, 0}}
    )

    append(
        &triangle_state.indices,
        index, index + 1, index + 2,
        index, index + 2, index + 3
    )
}

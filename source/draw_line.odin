package imdd3

import glm "core:math/linalg/glsl"

LINE_VERTEX_CAP :: 16384

Line_Vertex :: struct {
    position: [3]f32,
    radius: f32,
    color: u32,
    distance: f32,
    dash: f32,
    is_rounded: b32,
}

Line_State :: struct {
    vertices: [dynamic]Line_Vertex,
}

line_state: Line_State

line_init :: proc() {
    line_state.vertices = make([dynamic]Line_Vertex, 0, LINE_VERTEX_CAP)
}

line_destroy :: proc() {
    delete(line_state.vertices)
}

line_render :: proc() {
    renderer.interface.line_render(line_state.vertices[:])

    clear(&line_state.vertices)
}

// API
draw_line :: proc(point0: [3]f32, point1: [3]f32, width: f32, color: u32, dash: [2]f32 = {}, is_rounded := false) {
    radius := width * 0.5
    distance := dash[0] + glm.distance(point0, point1)

    append(&line_state.vertices,
        Line_Vertex{point0, radius, color, dash[0], dash[1], b32(is_rounded)},
        Line_Vertex{point1, radius, color, distance, dash[1], b32(is_rounded)}
    )
}

draw_line_cap :: proc(point0: [3]f32, point1: [3]f32, width: f32, color: u32, cap_type: Stroke_Cap_Type = .None) {
    if cap_type == .None {
        return
    }

    dir := glm.normalize(point1 - point0)
    radius := width * 0.5
    cap_start := point1
    cap_end := cap_start + dir * radius

    #partial switch cap_type {
    case .Square:
        append(&line_state.vertices,
            Line_Vertex{cap_start, radius, color, 0, 0, b32(false)},
            Line_Vertex{cap_end, radius, color, 0, 0, b32(false)}
        )
    case .Triangle:
        append(&line_state.vertices,
            Line_Vertex{cap_start, radius, color, 0, 0, b32(false)},
            Line_Vertex{cap_end, 0, color, 0, 0, b32(false)}
        )
    case .Round:
        append(&line_state.vertices,
            Line_Vertex{cap_start, radius, color, 0, 0, b32(true)},
            Line_Vertex{cap_end, radius, color, 0, 0, b32(true)}
        )
    }
}

draw_line_strip :: proc(points: [][3]f32, width: f32, color: u32, dash: f32 = 0, is_looped := false, join_type: Stroke_Join_Type = .None, cap_type: Stroke_Cap_Type = .None) {
    if len(points) < 2 {
        return
    }

    count := len(points)
    segment_count := is_looped ? count : count - 1

    if !is_looped {
        draw_line_cap(points[1], points[0], width, color, cap_type)
    }

    prev_end: [3]f32
    first_start: [3]f32
    total_distance: f32 = 0

    for i in 0 ..< segment_count {
        curr := points[i]
        next := points[(i + 1) % count]

        start := curr
        end := next

        if join_type != .None {
            seg_dir := glm.normalize(next - curr)

            if is_looped || i > 0 {
                start = curr + seg_dir
            }

            if is_looped || i < segment_count - 1 {
                end = next - seg_dir
            }
        }

        if i == 0 {
            first_start = start
        }

        if join_type != .None && i > 0 {
            draw_curve(prev_end, curr, start, width, color)
        }

        draw_line(start, end, width, color, dash = {total_distance, dash})

        total_distance += glm.distance(start, end)
        prev_end = end
    }

    if is_looped {
        if join_type != .None {
            draw_curve(prev_end, points[0], first_start, width, color)
        }
    } else {
        draw_line_cap(points[count - 2], points[count - 1], width, color, cap_type)
    }
}


draw_line_arrow :: proc(point0: [3]f32, point1: [3]f32, width: f32, head_size: f32, color: u32) {
    diff := point1 - point0
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    body_end := point1 - dir * head_size

    draw_line(point0, body_end, width, color)

    append(&line_state.vertices,
        Line_Vertex{body_end, head_size * 0.5, color, 0, 0, b32(false)},
        Line_Vertex{point1, 0, color, 0, 0, b32(false)}
    )
}

draw_line_grid :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(tangent, normal))
    extent := size / 2

    for x := -extent.x; x <= extent.x + 0.001; x += cell_size.x {
        point0 := center + tangent * x - bitangent * extent.y
        point1 := center + tangent * x + bitangent * extent.y

        draw_line(point0, point1, line_width, color)
    }

    for y := -extent.y; y <= extent.y + 0.001; y += cell_size.y {
        point0 := center - tangent * extent.x + bitangent * y
        point1 := center + tangent * extent.x + bitangent * y

        draw_line(point0, point1, line_width, color)
    }
}

draw_line_grid_xy :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_line_grid(center, {0, 0, -1}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_line_grid_xz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_line_grid(center, {0, 1, 0}, {1, 0, 0}, size, cell_size, line_width, color)
}

draw_line_grid_yz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32) {
    draw_line_grid(center, {1, 0, 0}, {0, 1, 0}, size, cell_size, line_width, color)
}

draw_line_cross :: proc(center: [3]f32, size: f32, line_width: f32, color: u32) {
    half := size * 0.5

    draw_line(center - {half, 0, 0}, center + {half, 0, 0}, line_width, color)
    draw_line(center - {0, half, 0}, center + {0, half, 0}, line_width, color)
    draw_line(center - {0, 0, half}, center + {0, 0, half}, line_width, color)
}

draw_line_gizmo :: proc(position: [3]f32, size: f32, line_width: f32) {
    head_size := line_width * 3

    draw_line_arrow(position, position + {size, 0, 0}, line_width, head_size, 0xff0000ff)
    draw_line_arrow(position, position + {0, size, 0}, line_width, head_size, 0x00ff00ff)
    draw_line_arrow(position, position + {0, 0, size}, line_width, head_size, 0x0000ffff)
}

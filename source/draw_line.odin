package imdd3

import glm "core:math/linalg/glsl"

LINE_VERTEX_CAP :: 16384

Line_Vertex :: struct {
    position: [3]f32,
    radius: f32,
    color: u32,
    distance: f32,
    dash_length: f32,
    plane_perp: [3]f32,
    is_rounded: b32,
}

Line_State :: struct {
    vertices: [dynamic]Line_Vertex,
}

Line_Cap_Type :: enum {
    None,
    Square,
    Triangle,
    Circle
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
draw_line :: proc(point0: [3]f32, point1: [3]f32, width: f32, color: u32, normal: [3]f32 = {}, tangent: [3]f32 = {}, dash_length: f32 = 0, start_distance: f32 = 0, is_rounded := false) {
    radius := width * 0.5
    distance := start_distance + glm.distance(point0, point1)

    plane_perp: [3]f32
    if normal != {} {
        dir := glm.normalize(point1 - point0)
        plane_perp = glm.normalize(glm.cross(normal, dir))
    }

    append(&line_state.vertices,
        Line_Vertex{point0, radius, color, start_distance, dash_length, plane_perp, b32(is_rounded)},
        Line_Vertex{point1, radius, color, distance, dash_length, plane_perp, b32(is_rounded)}
    )
}

draw_line_cap :: proc(point0: [3]f32, dir: [3]f32, width: f32, color: u32, cap_type: Line_Cap_Type = .None) {
    if cap_type == .None {
        return
    }

    radius := width * 0.5
    point1 := point0 + dir * radius

    #partial switch cap_type {
    case .Square:
        append(&line_state.vertices,
            Line_Vertex{point0, radius, color, 0, 0, {}, b32(false)},
            Line_Vertex{point1, radius, color, 0, 0, {}, b32(false)}
        )
    case .Triangle:
        append(&line_state.vertices,
            Line_Vertex{point0, radius, color, 0, 0, {}, b32(false)},
            Line_Vertex{point1, 0, color, 0, 0, {}, b32(false)}
        )
    case .Circle:
        append(&line_state.vertices,
            Line_Vertex{point0, radius, color, 0, 0, {}, b32(true)},
            Line_Vertex{point1, radius, color, 0, 0, {}, b32(true)}
        )
    }
}

draw_line_strip :: proc(points: [][3]f32, width: f32, color: u32, cap_type: Line_Cap_Type = .None, is_looped := false, dash_length: f32 = 0) {
    if len(points) < 2 {
        return
    }

    count := len(points)
    segment_count := is_looped ? count : count - 1

    if !is_looped {
        dir := glm.normalize(points[0] - points[1])
        draw_line_cap(points[0], dir, width, color, cap_type)
    }

    prev_end: [3]f32
    first_start: [3]f32
    total_distance: f32 = 0

    for i in 0 ..< segment_count {
        curr := points[i]
        next := points[(i + 1) % count]
        seg_dir := glm.normalize(next - curr)

        start := curr
        end := next

        if is_looped || i > 0 {
            start = curr + seg_dir
        }

        if is_looped || i < segment_count - 1 {
            end = next - seg_dir
        }

        if i == 0 {
            first_start = start
        }

        if i > 0 {
            draw_curve(prev_end, curr, start, width, color)
        }

        draw_line(start, end, width, color, dash_length = dash_length, start_distance = total_distance)
        total_distance += glm.distance(start, end)

        prev_end = end
    }

    if is_looped {
        draw_curve(prev_end, points[0], first_start, width, color)
    } else {
        dir := glm.normalize(points[count - 1] - points[count - 2])
        draw_line_cap(points[count - 1], dir, width, color, cap_type)
    }
}

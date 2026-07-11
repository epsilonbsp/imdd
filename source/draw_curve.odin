package imdd3

import glm "core:math/linalg/glsl"

CURVE_VERTEX_CAP :: 16384

Curve_Vertex :: struct {
    position: [3]f32,
    weight: f32,
    radius: f32,
    color: u32,
}

Curve_State :: struct {
    vertices: [dynamic]Curve_Vertex,
}

curve_state: Curve_State

curve_init :: proc() {
    curve_state.vertices = make([dynamic]Curve_Vertex, 0, CURVE_VERTEX_CAP)
}

curve_destroy :: proc() {
    delete(curve_state.vertices)
}

curve_render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    state.renderer.curve_render(curve_state.vertices[:], projection, view)

    clear(&curve_state.vertices)
}

draw_curve :: proc(p0: [3]f32, p1: [3]f32, p2: [3]f32, width: f32, color: u32) {
    radius := width * 0.5

    append(&curve_state.vertices,
        Curve_Vertex{p0, 1, radius, color},
        Curve_Vertex{p1, 1, radius, color},
        Curve_Vertex{p2, 1, radius, color}
    )
}

draw_arc :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, angle0: f32, angle1: f32, width: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))

    half_angle := (angle1 - angle0) * 0.5
    mid_angle := (angle0 + angle1) * 0.5

    w := glm.cos(half_angle)
    p1_radius := radius / w

    p0 := center + tangent * (radius * glm.cos(angle0)) + bitangent * (radius * glm.sin(angle0))
    p1 := center + tangent * (p1_radius * glm.cos(mid_angle)) + bitangent * (p1_radius * glm.sin(mid_angle))
    p2 := center + tangent * (radius * glm.cos(angle1)) + bitangent * (radius * glm.sin(angle1))

    line_radius := width * 0.5

    append(&curve_state.vertices,
        Curve_Vertex{p0, 1, line_radius, color},
        Curve_Vertex{p1, w, line_radius, color},
        Curve_Vertex{p2, 1, line_radius, color}
    )
}

draw_circle :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, width: f32, color: u32) {
    segment: f32 = glm.PI * 2 / 3

    draw_arc(center, normal, tangent, radius, segment * 0, segment * 1, width, color)
    draw_arc(center, normal, tangent, radius, segment * 1, segment * 2, width, color)
    draw_arc(center, normal, tangent, radius, segment * 2, segment * 3, width, color)
}

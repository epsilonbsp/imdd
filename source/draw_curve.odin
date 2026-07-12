package imdd3

import glm "core:math/linalg/glsl"

CURVE_VERTEX_CAP :: 16384

Curve_Vertex :: struct {
    position: [3]f32,
    radius: f32,
    weight: f32,
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

curve_render :: proc() {
    renderer.interface.curve_render(curve_state.vertices[:])

    clear(&curve_state.vertices)
}

// API
draw_curve :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, width: f32, color: u32) {
    radius := width * 0.5

    append(&curve_state.vertices,
        Curve_Vertex{point0, radius, 1, color},
        Curve_Vertex{point1, radius, 1, color},
        Curve_Vertex{point2, radius, 1, color}
    )
}

draw_arc :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, angle0: f32, angle1: f32, width: f32, color: u32) {
    bitangent := glm.normalize(glm.cross(normal, tangent))
    mid_angle := (angle0 + angle1) * 0.5
    half_angle := (angle1 - angle0) * 0.5
    weight := glm.cos(half_angle)
    arc_radius := radius / weight

    point0 := center + tangent * (radius * glm.cos(angle0)) + bitangent * (radius * glm.sin(angle0))
    point1 := center + tangent * (arc_radius * glm.cos(mid_angle)) + bitangent * (arc_radius * glm.sin(mid_angle))
    point2 := center + tangent * (radius * glm.cos(angle1)) + bitangent * (radius * glm.sin(angle1))

    line_radius := width * 0.5

    append(&curve_state.vertices,
        Curve_Vertex{point0, line_radius, 1, color},
        Curve_Vertex{point1, line_radius, weight, color},
        Curve_Vertex{point2, line_radius, 1, color}
    )
}

draw_ring :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, width: f32, color: u32) {
    segment: f32 = glm.PI * 2 / 3

    draw_arc(center, normal, tangent, radius, segment * 0, segment * 1, width, color)
    draw_arc(center, normal, tangent, radius, segment * 1, segment * 2, width, color)
    draw_arc(center, normal, tangent, radius, segment * 2, segment * 3, width, color)
}

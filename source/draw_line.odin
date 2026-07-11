package imdd3

LINE_VERTEX_CAP :: 16384

Line_Vertex :: struct {
    position: [3]f32,
    radius: f32,
    is_connected: b32,
    color: u32,
    pad: u64,
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

line_render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    state.renderer.line_render(line_state.vertices[:], projection, view)

    clear(&line_state.vertices)
}

draw_line :: proc(point0: [3]f32, point1: [3]f32, width: f32, color: u32) {
    radius := width * 0.5

    append(&line_state.vertices,
        Line_Vertex{point0, radius, true, color, 0},
        Line_Vertex{point1, radius, false, color, 0}
    )
}

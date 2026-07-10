package imdd3

// Renderer data
VERTEX_CAP :: 16384
INDEX_CAP :: VERTEX_CAP * 3 / 2

// Vertex size: 48 bytes
Vertex :: struct {
    mode: u32,
    position: [3]f32,
    tex_coord: [2]f32,
    tex_index: u32,
    colors: [2]u32,
    params: [4]f32,
}

State :: struct {
    // Implementation
    renderer: Renderer,

    // Renderer data
    vertices: [dynamic]Vertex,
    indices: [dynamic]u32,

    fonts: [3]Font,
    font_weight: Font_Weight,
    icons: Icons,

    // Shape data (bucketed by type)
    shape_data: [Shape_Type][dynamic]Debug_Shape,
    shape_data_len: [Shape_Type]i32,
}

state: State

init :: proc(renderer: Renderer) {
    // Implementation
    state.renderer = renderer
    state.renderer.init()

    // Renderer data
    state.vertices = make([dynamic]Vertex, 0, VERTEX_CAP)
    state.indices = make([dynamic]u32, 0, INDEX_CAP)

    load_fonts()
    load_icons()

    // Shape
    init_shape_rdr()

    // Primitive
    primitive_renderer_init()
}

destroy :: proc() {
    // Implementation
    state.renderer.destroy()

    // Renderer data
    delete(state.vertices)
    delete(state.indices)

    delete(state.icons.icons)

    // Shape
    free_shape_rdr()

    // Primitive
    primitive_renderer_destroy()
}

render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32, resolution: [2]f32) {
    state.renderer.flush(state.vertices[:], state.indices[:], projection * view)

    clear(&state.vertices)
    clear(&state.indices)

    render_shape_rdr(resolution, projection, view)

    // Primitive
    primitive_renderer_render(resolution, projection, view)
}

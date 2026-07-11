package imdd3

State :: struct {
    // Implementation
    renderer: Renderer,

    // Renderer data


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
    delete(state.icons.icons)

    // Shape
    free_shape_rdr()

    // Primitive
    primitive_renderer_destroy()
}

render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32, resolution: [2]f32) {
    line_render(projection, view)
    triangle_render(projection, view)

    // Old
    // render_shape_rdr(resolution, projection, view)
    // primitive_renderer_render(resolution, projection, view)
}

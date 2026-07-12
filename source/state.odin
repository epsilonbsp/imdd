package imdd3

State :: struct {
    // Implementation
    renderer: Renderer,

    // Renderer data
    fonts: [3]Font,
    font_weight: Font_Weight,
    icons: Icons,
}

state: State

init :: proc(renderer: Renderer) {
    // Implementation
    state.renderer = renderer
    state.renderer.init()

    // Renderer data
    load_fonts()
    load_icons()

    // Pipelines
    line_init()
    curve_init()
    triangle_init()
    lineprim_init()
    triprim_init()
}

destroy :: proc() {
    // Implementation
    state.renderer.destroy()

    // Renderer data
    delete(state.icons.icons)

    // Pipelines
    line_destroy()
    curve_destroy()
    triangle_destroy()
    lineprim_destroy()
    triprim_destroy()
}

render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32, viewport: [2]f32) {
    line_render(projection, view)
    curve_render(projection, view)
    triangle_render(projection, view)
    lineprim_render(projection, view, viewport)
    triprim_render(projection, view, viewport)
}

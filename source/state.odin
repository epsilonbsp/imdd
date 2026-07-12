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

    lineprim_init()
    triprim_init()
}

destroy :: proc() {
    // Implementation
    state.renderer.destroy()

    // Renderer data
    delete(state.icons.icons)

    lineprim_destroy()
    triprim_destroy()
}

render :: proc(projection: matrix[4, 4]f32, view: matrix[4, 4]f32, resolution: [2]f32) {
    line_render(projection, view)
    curve_render(projection, view)
    triangle_render(projection, view)
    lineprim_render(resolution, projection, view)
    triprim_render(resolution, projection, view)
}

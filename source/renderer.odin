package imdd3

import glm "core:math/linalg/glsl"

Renderer_Interface :: struct {
    init: proc(),
    destroy: proc(),

    add_texture: proc(width: i32, height: i32, data: []u8) -> u32,
    remove_texture: proc(handle: u32),
    update_texture: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8),

    line_render: proc(vertices: []Line_Vertex, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
    triangle_render: proc(vertices: []Triangle_Vertex, indices: []u32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
    curve_render: proc(vertices: []Curve_Vertex, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),

    lineprim_init: proc(vertices: []glm.vec3, indices: []u32, ranges: [Lineprim_Type]Lineprim_Range),
    lineprim_render: proc(data: [Lineprim_Type][]Lineprim_Instance, projection: matrix[4, 4]f32, view: matrix[4, 4]f32, viewport: [2]f32),

    triprim_init: proc(vertices: []Triprim_Vertex, indices: []u32, ranges: [Triprim_Type]Triprim_Range),
    triprim_render: proc(data: [Triprim_Type][]Triprim_Instance, projection: matrix[4, 4]f32, view: matrix[4, 4]f32, viewport: [2]f32),
}

Renderer :: struct {
    // Implementation
    interface: Renderer_Interface,

    // Renderer data
    fonts: [3]Font,
    font_weight: Font_Weight,
    icons: Icons,
}

renderer: Renderer

init :: proc(interface: Renderer_Interface) {
    // Implementation
    renderer.interface = interface
    renderer.interface.init()

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
    renderer.interface.destroy()

    // Renderer data
    delete(renderer.icons.icons)

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

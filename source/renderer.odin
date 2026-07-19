package imdd3

Renderer_Interface :: struct {
    init: proc(),
    destroy: proc(),
    prepare_renderer: proc(viewport: [2]i32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),

    add_texture: proc(width: i32, height: i32, data: []u8) -> u32,
    remove_texture: proc(handle: u32),
    update_texture: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8),
    line_render: proc(vertices: []Line_Vertex),
    triangle_render: proc(vertices: []Triangle_Vertex, indices: []u32),
    curve_render: proc(vertices: []Curve_Vertex),
    lineprim_init: proc(vertices: []Lineprim_Vertex, indices: []u32, ranges: [Lineprim_Type]Lineprim_Range),
    lineprim_render: proc(data: [Lineprim_Type][]Lineprim_Instance),
    triprim_init: proc(vertices: []Triprim_Vertex, ranges: [Triprim_Type]Triprim_Range),
    triprim_render: proc(data: []Triprim_Instance, max_vertex_count: u32),
}

Renderer :: struct {
    interface: Renderer_Interface,
    fonts: [3]Font,
    font_weight: Font_Weight,
    icons: Icons,
}

renderer: Renderer

init_renderer :: proc(interface: Renderer_Interface) {
    renderer.interface = interface
    renderer.interface.init()

    load_fonts()
    load_icons()

    line_init()
    curve_init()
    triangle_init()
    lineprim_init()
    triprim_init()
}

destroy_renderer :: proc() {
    renderer.interface.destroy()

    delete(renderer.icons.icons)

    line_destroy()
    curve_destroy()
    triangle_destroy()
    lineprim_destroy()
    triprim_destroy()
}

render :: proc(viewport: [2]i32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    renderer.interface.prepare_renderer(viewport, projection, view)

    triprim_render()
    lineprim_render()
    line_render()
    curve_render()
    triangle_render()
}

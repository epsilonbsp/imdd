package imdd3

import glm "core:math/linalg/glsl"

Renderer :: struct {
    // 2d
    init: proc(),
    destroy: proc(),
    set_clip_rect: proc(x: i32, y: i32, w: i32, h: i32),
    clear_clip_rect: proc(),
    add_texture: proc(width: i32, height: i32, data: []u8) -> u32,
    remove_texture: proc(handle: u32),
    update_texture: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8),

    // lineprim
    lineprim_init: proc(vertices: []glm.vec3, indices: []u32, ranges: [Lineprim_Type]Lineprim_Range),
    lineprim_destroy: proc(),
    lineprim_render: proc(data: [Lineprim_Type][]Lineprim_Instance, resolution: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),

    // triprim
    triprim_init: proc(vertices: []Triprim_Vertex, indices: []u32, offset: [Triprim_Type]Triprim_Range),
    triprim_destroy: proc(),
    triprim_render: proc(data: [Triprim_Type][]Triprim_Instance, viewport: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),

    line_render: proc(vertices: []Line_Vertex, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
    triangle_render: proc(vertices: []Triangle_Vertex, indices: []u32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
    curve_render: proc(vertices: []Curve_Vertex, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
}

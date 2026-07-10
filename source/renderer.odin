package imdd3

import glm "core:math/linalg/glsl"

Renderer :: struct {
    // 2d
    init: proc(),
    destroy: proc(),
    flush: proc(vertices: []Vertex, indices: []u32, projection: matrix[4, 4]f32),
    set_clip_rect: proc(x: i32, y: i32, w: i32, h: i32),
    clear_clip_rect: proc(),
    add_texture: proc(width: i32, height: i32, data: []u8) -> u32,
    remove_texture: proc(handle: u32),
    update_texture: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8),

    // shape
    shape_init: proc(vertices: []glm.vec3, indices: []u32, offset: [Shape_Type]Index_Offset),
    shape_destroy: proc(),
    shape_render: proc(data: [Shape_Type][]Debug_Shape, resolution: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),

    // primitive
    primitive_renderer_init: proc(vertices: []Primitive_Vertex, indices: []u32, offset: [Primitive_Type]Primitive_Range),
    primitive_renderer_destroy: proc(),
    primitive_renderer_render: proc(data: [Primitive_Type][]Primitive_Instance, viewport: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32),
}

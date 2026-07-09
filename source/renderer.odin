package imdd3

Renderer :: struct {
    init: proc(),
    destroy: proc(),
    flush: proc(vertices: []Vertex, indices: []u32, projection: matrix[4, 4]f32),
    set_clip_rect: proc(x: i32, y: i32, w: i32, h: i32),
    clear_clip_rect: proc(),
    add_texture: proc(width: i32, height: i32, data: []u8) -> u32,
    remove_texture: proc(handle: u32),
    update_texture: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8),
}

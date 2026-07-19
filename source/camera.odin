package imdd3

Camera :: struct {
    position: [3]f32,
    forward: [3]f32,
    fov: f32,
    projection: matrix[4, 4]f32,
    view: matrix[4, 4]f32,
    ray_direction: [3]f32,
}

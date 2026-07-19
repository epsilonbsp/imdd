package imdd3

Camera_Info :: struct {
    ray_origin: [3]f32,
    ray_direction: [3]f32,
    fov: f32,
}

camera: Camera_Info

set_camera :: proc(info: Camera_Info) {
    camera = info
}

init :: proc(platform: Platform_Interface, renderer: Renderer_Interface) {
    init_platform(platform)
    init_renderer(renderer)
}

destroy :: proc() {
    destroy_platform()
    destroy_renderer()
}

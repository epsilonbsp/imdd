package imdd3

State :: struct {
    camera: Camera
}

state: State

init :: proc(platform: Platform_Interface, renderer: Renderer_Interface) {
    init_platform(platform)
    init_renderer(renderer)
}

destroy :: proc() {
    destroy_platform()
    destroy_renderer()
}

update :: proc(camera: Camera) {
    state.camera = camera
}

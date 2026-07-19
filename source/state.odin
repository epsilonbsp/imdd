package imdd3

init :: proc(platform: Platform_Interface, renderer: Renderer_Interface) {
    init_platform(platform)
    init_renderer(renderer)
}

destroy :: proc() {
    destroy_platform()
    destroy_renderer()
}

new_frame :: proc() {

}

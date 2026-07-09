package example

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"
import imdd3 "../../source"

WINDOW_TITLE :: "IMDD3"
WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6

OUTPUT_VS :: `#version 460 core
    out vec2 v_tex_coord;

    const vec2 positions[] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );

    const vec2 tex_coords[] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 1.0)
    );

    void main() {
        gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
        v_tex_coord = tex_coords[gl_VertexID];
    }
`

OUTPUT_FS :: `#version 460 core
    precision highp float;

    in vec2 v_tex_coord;

    out vec4 o_frag_color;

    uniform sampler2D sa_texture;

    void main() {
        o_frag_color = texture(sa_texture, v_tex_coord);
    }
`

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.printf("SDL ERROR: %s\n", sdl.GetError())

        return
    }

    defer sdl.Quit()

    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfile.CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL, .RESIZABLE})
    defer sdl.DestroyWindow(window)

    gl_context := sdl.GL_CreateContext(window)
    defer sdl.GL_DestroyContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

    sdl.SetWindowPosition(window, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED)
    _ = sdl.SetWindowRelativeMouseMode(window, true)

    viewport_x, viewport_y: i32; sdl.GetWindowSize(window, &viewport_x, &viewport_y)
    key_state := sdl.GetKeyboardState(nil)
    time: u64 = sdl.GetTicks()
    time_delta : f32 = 0
    time_last := time

    camera: Camera; init_camera(&camera)

    movement_speed: f32 = 256
    yaw_speed: f32 = 0.002
    pitch_speed: f32 = 0.002
    zoom_speed: f32 = 20

    debug_camera: Camera; init_camera(&debug_camera)
    debug_camera.position = {0, 0, 256}
    debug_camera.near = 1
    debug_camera.far = 256
    debug_camera.fov = 45
    compute_camera_projection(&debug_camera, f32(viewport_x), f32(viewport_y))
    compute_camera_view(&debug_camera)

    output_shader: imdd3.Shader
    imdd3.make_shader(&output_shader, gl.load_shaders_source(OUTPUT_VS, OUTPUT_FS))

    imdd3.debug_init(WINDOW_WIDTH, WINDOW_HEIGHT); defer imdd3.debug_free()

    mesh: imdd3.Debug_Mesh;
    imdd3.debug_mesh_box3(&mesh, {-192, 96, 256}, {64, 128, 64}, 0xaa0000_ff)
    imdd3.debug_mesh_box3(&mesh, {-192, 0, 256}, {128, 64, 128}, 0x0000aa_ff)

    imdd3.build_debug_mesh(&mesh); defer imdd3.destroy_debug_mesh(&mesh)

    loop: for {
        time = sdl.GetTicks()
        time_delta = f32(time - time_last) / 1000
        time_last = time

        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    break loop
                case .WINDOW_RESIZED:
                    sdl.GetWindowSize(window, &viewport_x, &viewport_y)

                    imdd3.debug_resize(viewport_x, viewport_y)
                case .KEY_DOWN:
                    if event.key.scancode == sdl.Scancode.ESCAPE {
                        _ = sdl.SetWindowRelativeMouseMode(window, !sdl.GetWindowRelativeMouseMode(window))
                    }
                case .MOUSE_MOTION:
                    if sdl.GetWindowRelativeMouseMode(window) {
                        rotate_camera(&camera, event.motion.xrel * yaw_speed, event.motion.yrel * pitch_speed, 0)
                    }
            }
        }

        if (sdl.GetWindowRelativeMouseMode(window)) {
            speed := time_delta * movement_speed

            if key_state[sdl.Scancode.A] {
                move_camera(&camera, {-speed, 0, 0})
            }

            if key_state[sdl.Scancode.D] {
                move_camera(&camera, {speed, 0, 0})
            }

            if key_state[sdl.Scancode.S] {
                move_camera(&camera, {0, 0, -speed})
            }

            if key_state[sdl.Scancode.W] {
                move_camera(&camera, {0, 0, speed})
            }
        }

        compute_camera_projection(&camera, f32(viewport_x), f32(viewport_y))
        compute_camera_view(&camera)

        imdd3.debug_grid_xz({0, -2, 0}, {16384, 16384}, {32, 32}, 1, 0xffffff_ff)

        imdd3.debug_point({-64, 0, 128}, 4, 0x8a7be3_ff)
        imdd3.debug_point({0, 0, 128}, 8, 0x7be3e1_ff)
        imdd3.debug_point({64, 0, 128}, 12, 0xe3da7b_ff)

        imdd3.debug_arrow({0, 0, 0}, {64, 0, 0}, 2, 0xcc0000_ff)
        imdd3.debug_arrow({0, 0, 0}, {0, 64, 0}, 2, 0x00cc00_ff)
        imdd3.debug_arrow({0, 0, 0}, {0, 0, -64}, 2, 0x0000cc_ff)

        imdd3.debug_aabb({-192, 32, -128}, {64, 64, 64}, 0xebbe60_ff)
        imdd3.debug_cylinder_aa({-64, 32, -128}, {32, 64}, 0x9fe685_ff)
        imdd3.debug_cone_aa({64, 32, -128}, {32, 64}, 0x4963e6_ff)
        imdd3.debug_sphere({192, 32, -128}, 32, 0xe68ac4_ff)

        imdd3.debug_frustum(debug_camera.projection * debug_camera.view, 0xd1496b_ff)
        imdd3.debug_mesh(&mesh)

        imdd3.debug_text_world("Hello, World!", {0, 256, 1}, 64, 0xff0000_ff)
        imdd3.debug_text_world("TEST", {0, 256 + 64, 1}, 64, 0x0000ff_ff)

        imdd3.debug_prepare(
            camera.position,
            camera.forward,
            camera.projection,
            camera.view
        )
        imdd3.debug_render()

        gl.Viewport(0, 0, viewport_x, viewport_y)
        gl.ClearColor(0, 0, 0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, imdd3.debug_get_framebuffer().color_tbo)

        imdd3.use_shader(&output_shader)
        gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)

        sdl.GL_SwapWindow(window)
    }
}

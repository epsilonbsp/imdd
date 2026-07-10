package example

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

import imdd3 "../../source"
import imdd3_impl_gl "../../source/impl/gl"

WINDOW_TITLE :: "IMDD3"
WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6

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

    imdd3.init(imdd3_impl_gl.interface())
    defer imdd3.destroy()

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

        gl.Viewport(0, 0, viewport_x, viewport_y)
        gl.ClearColor(0.5, 0.5, 0.5, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        // imdd3.point({}, camera.forward, camera.right, 4, 0xffffffff)

        imdd3.grid_xy({}, {128, 128}, 16, 1, 0xff0000ff)
        // imdd3.grid_xz({}, {128, 128}, 16, 1, 0x00ff00ff)
        // imdd3.grid_yz({}, {128, 128}, 16, 1, 0x000ffff)

        // imdd3.line({}, {0, 128, 0}, camera.forward, camera.right, 8, 0x00ff00ff)
        // imdd3.arrow({}, {0, 128, 0}, camera.forward, camera.right, 8, 16, 0x00ff00ff)

        // imdd3.text({}, {0, 0, -1}, {1, 0, 0}, "Hello, World!", 16, 16, 0xff00ffff)

        // imdd3.frustum(debug_camera.projection * debug_camera.view, camera.forward, camera.right, 0.5, 0xd1496b_ff)

        imdd3.primitive_aabb({-192, 32, -128}, {64, 64, 64}, 0xebbe60_ff)
        // imdd3.debug_aabb({-192, 32, -128}, {64, 64, 64}, 0xebbe60_ff)
        imdd3.debug_cylinder_aa({-64, 32, -128}, {32, 64}, 0x9fe685_ff)
        imdd3.debug_cone_aa({64, 32, -128}, {32, 64}, 0x4963e6_ff)
        imdd3.debug_sphere({192, 32, -128}, 32, 0xe68ac4_ff)

        imdd3.render(camera.projection, camera.view, {f32(viewport_x), f32(viewport_y)})

        sdl.GL_SwapWindow(window)
    }
}

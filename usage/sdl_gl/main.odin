package example

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

import imdd3 "../../source"
import imdd3_impl_sdl "../../source/impl/sdl"
import imdd3_impl_gl "../../source/impl/gl"
import imdd3_test "../../source/test"

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
    camera_movement := Camera_Movement{
        movement_speed = 64,
        yaw_speed = 0.002,
        pitch_speed = 0.002,
    }

    imdd3.init(imdd3_impl_sdl.interface(window), imdd3_impl_gl.interface())
    defer imdd3.destroy()

    imdd3_test.init_demo()
    defer imdd3_test.destroy_demo()

    loop: for {
        time = sdl.GetTicks()
        time_delta = f32(time - time_last) / 1000
        time_last = time

        event: sdl.Event

        for sdl.PollEvent(&event) {
            imdd3_impl_sdl.process_event(event)

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
                        rotate_camera(&camera, event.motion.xrel * camera_movement.yaw_speed, event.motion.yrel * camera_movement.pitch_speed)
                    }
            }
        }

        if (sdl.GetWindowRelativeMouseMode(window)) {
            input_move_camera(&camera, {
                left = key_state[sdl.Scancode.A],
                right = key_state[sdl.Scancode.D],
                back = key_state[sdl.Scancode.S],
                forward = key_state[sdl.Scancode.W],
            }, camera_movement.movement_speed * time_delta)
        }

        compute_camera_projection(&camera, f32(viewport_x), f32(viewport_y))
        compute_camera_view(&camera)

        imdd3.update({
            position = camera.position,
            forward = camera.forward,
            fov = camera.fov,
            projection = camera.projection,
            view = camera.view
        })

        gl.Viewport(0, 0, viewport_x, viewport_y)
        gl.ClearColor(0.5, 0.5, 0.5, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        imdd3_test.show_demo()
        imdd3.flush_renderer()

        sdl.GL_SwapWindow(window)
    }
}

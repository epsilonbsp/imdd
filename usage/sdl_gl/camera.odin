package example

import glm "core:math/linalg/glsl"

Camera :: struct {
    position: [3]f32,
    forward: [3]f32,
    right: [3]f32,
    up: [3]f32,
    world_up: [3]f32,
    near: f32,
    far: f32,
    fov: f32,
    projection: matrix[4, 4]f32,
    view: matrix[4, 4]f32,
}

Camera_Movement :: struct {
    movement_speed: f32,
    yaw_speed: f32,
    pitch_speed: f32,
    zoom_speed: f32,
}

Camera_Input :: struct {
    left: bool,
    right: bool,
    back: bool,
    forward: bool,
    zoom_out: bool,
    zoom_in: bool,
}

init_camera :: proc(
    camera: ^Camera,
    position := glm.vec3{},
    forward := glm.vec3{0, 0, -1},
    right := glm.vec3{1, 0, 0},
    up := glm.vec3{0, 1, 0},
    world_up := glm.vec3{0, 1, 0},
    near := f32(1),
    far := f32(8192),
    fov := f32(90)
) {
    camera.position = position
    camera.forward = forward
    camera.right = right
    camera.up = up
    camera.world_up = world_up
    camera.near = near
    camera.far = far
    camera.fov = fov
    rotate_camera(camera, 0, 0)
}

move_camera :: proc(camera: ^Camera, direction: [3]f32) {
    camera.position += camera.forward * direction.z
    camera.position += camera.right * direction.x
    camera.position += camera.up * direction.y
}

rotate_camera :: proc(camera: ^Camera, yaw: f32, pitch: f32) {
    camera.up = camera.world_up

    // Yaw
    quat := glm.quatAxisAngle(camera.up, -yaw)
    camera.forward = glm.normalize(glm.quatMulVec3(quat, camera.forward))
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))

    // Pitch
    quat = glm.quatAxisAngle(camera.right, -pitch)
    forward := glm.normalize(glm.quatMulVec3(quat, camera.forward))

    if abs(glm.dot(forward, camera.up)) < 0.99 {
        camera.forward = forward
    }

    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

zoom_camera :: proc(camera: ^Camera, direction: f32, min: f32 = 1, max: f32 = 179) {
    camera.fov = glm.clamp(camera.fov + direction, min, max)
}

point_camera_at :: proc(camera: ^Camera, point: [3]f32) {
    if glm.distance(camera.position, point) < glm.F32_EPSILON {
        return
    }

    camera.up = camera.world_up
    camera.forward = glm.normalize(point - camera.position)
    camera.right = glm.normalize(glm.cross(camera.forward, camera.up))
    camera.up = glm.normalize(glm.cross(camera.right, camera.forward))
}

compute_camera_projection :: proc(camera: ^Camera, width: f32, height: f32) {
    camera.projection = glm.mat4Perspective(glm.radians(camera.fov), width / height, camera.near, camera.far)
}

compute_camera_view :: proc(camera: ^Camera) {
    camera.view = glm.mat4LookAt(camera.position, camera.position + camera.forward, camera.up)
}

input_move_camera :: proc(camera: ^Camera, input: Camera_Input, speed: f32) {
    if input.left {
        move_camera(camera, {-speed, 0, 0})
    }

    if input.right {
        move_camera(camera, {speed, 0, 0})
    }

    if input.back {
        move_camera(camera, {0, 0, -speed})
    }

    if input.forward {
        move_camera(camera, {0, 0, speed})
    }
}

input_zoom_camera :: proc(camera: ^Camera, input: Camera_Input, speed: f32, min: f32 = 1, max: f32 = 179) {
    if input.zoom_out {
        zoom_camera(camera, -speed, min, max)
    }

    if input.zoom_in {
        zoom_camera(camera, speed, min, max)
    }
}

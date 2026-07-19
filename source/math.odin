package imdd3

import "core:math"
import glm "core:math/linalg/glsl"

snap :: proc(v: f32, size: f32 = 1) -> f32 {
    return math.round(v / size) * size
}

snap3 :: proc(p: [3]f32, size: f32 = 1) -> [3]f32 {
    return {snap(p.x, size), snap(p.y, size), snap(p.z, size)}
}

closest_t_on_line_to_ray :: proc(ray_origin: [3]f32, ray_direction: [3]f32, line_origin: [3]f32, line_direction: [3]f32) -> f32 {
    r := ray_origin - line_origin
    a := glm.dot(ray_direction, ray_direction)
    b := glm.dot(ray_direction, line_direction)
    c := glm.dot(ray_direction, r)
    e := glm.dot(line_direction, line_direction)
    f := glm.dot(line_direction, r)

    denom := a * e - b * b

    if abs(denom) < glm.F32_EPSILON {
        return 0
    }

    return (a * f - b * c) / denom
}

ray_plane_intersect :: proc(ray_origin: [3]f32, ray_direction: [3]f32, plane_point: [3]f32, plane_normal: [3]f32) -> (point: [3]f32, hit: bool) {
    denom := glm.dot(ray_direction, plane_normal)

    if abs(denom) < glm.F32_EPSILON {
        return {}, false
    }

    t := glm.dot(plane_point - ray_origin, plane_normal) / denom

    if t < 0 {
        return {}, false
    }

    return ray_origin + ray_direction * t, true
}

signed_angle_around_axis :: proc(from: [3]f32, to: [3]f32, axis: [3]f32) -> f32 {
    from_proj := glm.normalize(from - axis * glm.dot(from, axis))
    to_proj := glm.normalize(to - axis * glm.dot(to, axis))

    angle := glm.acos(glm.clamp(glm.dot(from_proj, to_proj), -1, 1))

    if glm.dot(glm.cross(from_proj, to_proj), axis) < 0 {
        angle = -angle
    }

    return angle
}

quat_rotation_xyz :: proc(rotation: [3]f32) -> glm.quat {
    return glm.quatAxisAngle({1, 0, 0}, rotation.x) * glm.quatAxisAngle({0, 1, 0}, rotation.y) * glm.quatAxisAngle({0, 0, -1}, rotation.z)
}

quat_rotation_dir :: proc(dir: [3]f32) -> glm.quat {
    if glm.dot(dir, [3]f32{0, 1, 0}) < -0.9999 {
        return glm.quatAxisAngle({1, 0, 0}, glm.PI)
    }

    return glm.quatFromMat4(glm.mat4Orientation(dir, {0, 1, 0}))
}

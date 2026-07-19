package imdd3

import glm "core:math/linalg/glsl"

GIZMO_ARROW_LENGTH :: f32(16)
GIZMO_AXIS_PICK_THRESHOLD :: f32(1)
GIZMO_PLANE_HANDLE_OFFSET :: f32(4)
GIZMO_PLANE_HANDLE_SIZE :: f32(4)
GIZMO_HEAD_SIZE_RATIO :: f32(2)
GIZMO_SCALE_HANDLE_RATIO :: f32(0.15)

GIZMO_COLOR_X :: u32(0xff4d4dff)
GIZMO_COLOR_Y :: u32(0x4dff4dff)
GIZMO_COLOR_Z :: u32(0x4d4dffff)
GIZMO_COLOR_XY :: u32(0x4d4dffaa)
GIZMO_COLOR_XZ :: u32(0x4dff4daa)
GIZMO_COLOR_YZ :: u32(0xff4d4daa)
GIZMO_HOVER_COLOR :: u32(0xffffffff)

GIZMO_SCREEN_SIZE :: f32(0.1)

gizmo_screen_scale :: proc(position: [3]f32) -> f32 {
    // Depth along the view direction, not straight-line distance -- otherwise
    // a gizmo off-center on screen (radial distance > depth) gets scaled up
    // too much the further it sits from the screen center.
    distance := glm.dot(position - camera.ray_origin, camera.forward)

    return distance * glm.tan(glm.radians(camera.fov) * 0.5) * 2 * GIZMO_SCREEN_SIZE
}

Gizmo_Handle :: enum {
    None,
    X,
    Y,
    Z,
    XY,
    XZ,
    YZ,
}

Gizmo :: struct {
    hovered_handle: Gizmo_Handle,
    dragging_handle: Gizmo_Handle,
    drag_origin: [3]f32,
    drag_start_point: [3]f32,
    drag_start_dir: [3]f32,
    mouse_down_prev: bool,
}

gizmo: Gizmo

gizmo_axis_direction :: proc(axis: Gizmo_Handle) -> [3]f32 {
    switch axis {
    case .None, .XY, .XZ, .YZ:
        return {}
    case .X:
        return {1, 0, 0}
    case .Y:
        return {0, 1, 0}
    case .Z:
        return {0, 0, 1}
    }

    return {}
}

gizmo_plane_basis :: proc(handle: Gizmo_Handle) -> (a: [3]f32, b: [3]f32, normal: [3]f32) {
    switch handle {
    case .None, .X, .Y, .Z:
    case .XY:
        return {1, 0, 0}, {0, 1, 0}, {0, 0, 1}
    case .XZ:
        return {0, 0, 1}, {1, 0, 0}, {0, 1, 0}
    case .YZ:
        return {0, 1, 0}, {0, 0, 1}, {1, 0, 0}
    }

    return {}, {}, {}
}

gizmo_pick_axis :: proc(center: [3]f32, ray_origin: [3]f32, ray_direction: [3]f32, scale: f32) -> (handle: Gizmo_Handle, hit: bool) {
    k := scale / GIZMO_ARROW_LENGTH
    closest_distance := GIZMO_AXIS_PICK_THRESHOLD * k

    for candidate in ([]Gizmo_Handle{.X, .Y, .Z}) {
        direction := gizmo_axis_direction(candidate)
        line_t := closest_t_on_line_to_ray(ray_origin, ray_direction, center, direction)

        if line_t < 0 || line_t > scale {
            continue
        }

        ray_t := closest_t_on_line_to_ray(center, direction, ray_origin, ray_direction)
        point_on_axis := center + direction * line_t
        point_on_ray := ray_origin + ray_direction * ray_t
        distance := glm.length(point_on_axis - point_on_ray)

        if distance < closest_distance {
            closest_distance = distance
            handle = candidate
            hit = true
        }
    }

    return handle, hit
}

gizmo_pick_handle :: proc(center: [3]f32, ray_origin: [3]f32, ray_direction: [3]f32, scale: f32) -> (handle: Gizmo_Handle, hit: bool) {
    k := scale / GIZMO_ARROW_LENGTH
    offset_amount := GIZMO_PLANE_HANDLE_OFFSET * k
    size_amount := GIZMO_PLANE_HANDLE_SIZE * k

    for candidate in ([]Gizmo_Handle{.XY, .XZ, .YZ}) {
        a, b, normal := gizmo_plane_basis(candidate)
        point, ok := ray_plane_intersect(ray_origin, ray_direction, center, normal)

        if !ok {
            continue
        }

        offset := point - center
        u := glm.dot(offset, a)
        v := glm.dot(offset, b)

        if u >= offset_amount && u <= offset_amount + size_amount &&
           v >= offset_amount && v <= offset_amount + size_amount {
            return candidate, true
        }
    }

    return gizmo_pick_axis(center, ray_origin, ray_direction, scale)
}

gizmo_drag_point :: proc(handle: Gizmo_Handle, center: [3]f32, ray_origin: [3]f32, ray_direction: [3]f32) -> (point: [3]f32, ok: bool) {
    switch handle {
    case .X, .Y, .Z:
        direction := gizmo_axis_direction(handle)
        t := closest_t_on_line_to_ray(ray_origin, ray_direction, center, direction)

        return center + direction * t, true
    case .XY, .XZ, .YZ:
        _, _, normal := gizmo_plane_basis(handle)

        return ray_plane_intersect(ray_origin, ray_direction, center, normal)
    case .None:
    }

    return {}, false
}

gizmo_pick_ring :: proc(center: [3]f32, ray_origin: [3]f32, ray_direction: [3]f32, scale: f32) -> (handle: Gizmo_Handle, hit: bool) {
    k := scale / GIZMO_ARROW_LENGTH
    closest_distance := GIZMO_AXIS_PICK_THRESHOLD * k

    for candidate in ([]Gizmo_Handle{.X, .Y, .Z}) {
        normal := gizmo_axis_direction(candidate)
        point, ok := ray_plane_intersect(ray_origin, ray_direction, center, normal)

        if !ok {
            continue
        }

        distance := abs(glm.length(point - center) - scale)

        if distance < closest_distance {
            closest_distance = distance
            handle = candidate
            hit = true
        }
    }

    return handle, hit
}

gizmo_ring_direction :: proc(center: [3]f32, axis: [3]f32, ray_origin: [3]f32, ray_direction: [3]f32) -> (dir: [3]f32, ok: bool) {
    point := ray_plane_intersect(ray_origin, ray_direction, center, axis) or_return
    offset := point - center
    length := glm.length(offset)

    if length < glm.F32_EPSILON {
        return {}, false
    }

    return offset / length, true
}

gizmo_handle_color :: proc(handle: Gizmo_Handle, base_color: u32) -> u32 {
    if handle == gizmo.hovered_handle || handle == gizmo.dragging_handle {
        return GIZMO_HOVER_COLOR
    }

    return base_color
}

gizmo_draw_translate :: proc(position: [3]f32, scale: f32) {
    k := scale / GIZMO_ARROW_LENGTH
    offset_amount := GIZMO_PLANE_HANDLE_OFFSET * k
    size_amount := GIZMO_PLANE_HANDLE_SIZE * k
    width := k
    head_size := GIZMO_HEAD_SIZE_RATIO * k

    draw_arrow(position, position + gizmo_axis_direction(.X) * scale, width, head_size, gizmo_handle_color(.X, GIZMO_COLOR_X))
    draw_arrow(position, position + gizmo_axis_direction(.Y) * scale, width, head_size, gizmo_handle_color(.Y, GIZMO_COLOR_Y))
    draw_arrow(position, position + gizmo_axis_direction(.Z) * scale, width, head_size, gizmo_handle_color(.Z, GIZMO_COLOR_Z))

    plane_colors := [Gizmo_Handle]u32{.XY = GIZMO_COLOR_XY, .XZ = GIZMO_COLOR_XZ, .YZ = GIZMO_COLOR_YZ, .None = 0, .X = 0, .Y = 0, .Z = 0}

    for handle in ([]Gizmo_Handle{.XY, .XZ, .YZ}) {
        a, b, normal := gizmo_plane_basis(handle)
        square_center := position + (a + b) * (offset_amount + size_amount * 0.5)

        draw_rect(square_center, normal, a, {size_amount, size_amount}, gizmo_handle_color(handle, plane_colors[handle]))
    }
}

gizmo_draw_rotate :: proc(position: [3]f32, scale: f32) {
    k := scale / GIZMO_ARROW_LENGTH
    width := k

    draw_ring(position, gizmo_axis_direction(.X), gizmo_axis_direction(.Y), scale, width, gizmo_handle_color(.X, GIZMO_COLOR_X))
    draw_ring(position, gizmo_axis_direction(.Y), gizmo_axis_direction(.Z), scale, width, gizmo_handle_color(.Y, GIZMO_COLOR_Y))
    draw_ring(position, gizmo_axis_direction(.Z), gizmo_axis_direction(.X), scale, width, gizmo_handle_color(.Z, GIZMO_COLOR_Z))
}

gizmo_draw_scale :: proc(position: [3]f32, scale: f32) {
    k := scale / GIZMO_ARROW_LENGTH
    width := k
    colors := [Gizmo_Handle]u32{.None = 0, .X = GIZMO_COLOR_X, .Y = GIZMO_COLOR_Y, .Z = GIZMO_COLOR_Z, .XY = 0, .XZ = 0, .YZ = 0}
    handle_size := scale * GIZMO_SCALE_HANDLE_RATIO

    for handle in ([]Gizmo_Handle{.X, .Y, .Z}) {
        direction := gizmo_axis_direction(handle)
        handle_center := position + direction * (scale - handle_size * 0.5)
        color := gizmo_handle_color(handle, colors[handle])

        draw_cylinder_ab(position, handle_center, width, color)
        draw_box_aa(handle_center, {handle_size, handle_size, handle_size}, color)
    }
}

// API
gizmo_translate :: proc(position: [3]f32, grid: f32) -> (delta: [3]f32, active: bool) {
    ray_origin := camera.ray_origin
    ray_direction := camera.ray_direction

    mouse_down := get_mouse_down(0)
    pressed := mouse_down && !gizmo.mouse_down_prev
    released := !mouse_down && gizmo.mouse_down_prev
    gizmo.mouse_down_prev = mouse_down

    scale := gizmo_screen_scale(position)

    if gizmo.dragging_handle == .None {
        gizmo.hovered_handle, _ = gizmo_pick_handle(position, ray_origin, ray_direction, scale)

        if pressed && gizmo.hovered_handle != .None {
            if point, ok := gizmo_drag_point(gizmo.hovered_handle, position, ray_origin, ray_direction); ok {
                gizmo.dragging_handle = gizmo.hovered_handle
                gizmo.drag_origin = position
                gizmo.drag_start_point = point
            }
        }
    } else if released {
        gizmo.dragging_handle = .None
    } else if point, ok := gizmo_drag_point(gizmo.dragging_handle, gizmo.drag_origin, ray_origin, ray_direction); ok {
        delta = snap3(point - gizmo.drag_start_point, grid)
        active = true
    }

    gizmo_draw_translate(position, scale)

    return delta, active
}

gizmo_rotate :: proc(position: [3]f32, grid_degrees: f32) -> (origin: [3]f32, rotation: glm.quat, active: bool) {
    ray_origin := camera.ray_origin
    ray_direction := camera.ray_direction

    rotation = 1

    mouse_down := get_mouse_down(0)
    pressed := mouse_down && !gizmo.mouse_down_prev
    released := !mouse_down && gizmo.mouse_down_prev
    gizmo.mouse_down_prev = mouse_down

    scale := gizmo_screen_scale(position)

    if gizmo.dragging_handle == .None {
        gizmo.hovered_handle, _ = gizmo_pick_ring(position, ray_origin, ray_direction, scale)

        if pressed && gizmo.hovered_handle != .None {
            direction := gizmo_axis_direction(gizmo.hovered_handle)

            if dir, ok := gizmo_ring_direction(position, direction, ray_origin, ray_direction); ok {
                gizmo.dragging_handle = gizmo.hovered_handle
                gizmo.drag_origin = position
                gizmo.drag_start_dir = dir
            }
        }
    } else if released {
        gizmo.dragging_handle = .None
    } else {
        direction := gizmo_axis_direction(gizmo.dragging_handle)

        if current_dir, ok := gizmo_ring_direction(gizmo.drag_origin, direction, ray_origin, ray_direction); ok {
            angle := signed_angle_around_axis(gizmo.drag_start_dir, current_dir, direction)
            snapped_degrees := snap(glm.degrees(angle), grid_degrees)

            origin = gizmo.drag_origin
            rotation = glm.quatAxisAngle(direction, glm.radians(snapped_degrees))
            active = true
        }
    }

    gizmo_draw_rotate(position, scale)

    return origin, rotation, active
}

gizmo_scale :: proc(position: [3]f32) -> (origin: [3]f32, axis: [3]f32, factor: f32, active: bool) {
    ray_origin := camera.ray_origin
    ray_direction := camera.ray_direction

    factor = 1

    mouse_down := get_mouse_down(0)
    pressed := mouse_down && !gizmo.mouse_down_prev
    released := !mouse_down && gizmo.mouse_down_prev
    gizmo.mouse_down_prev = mouse_down

    scale := gizmo_screen_scale(position)

    if gizmo.dragging_handle == .None {
        gizmo.hovered_handle, _ = gizmo_pick_axis(position, ray_origin, ray_direction, scale)

        if pressed && gizmo.hovered_handle != .None {
            direction := gizmo_axis_direction(gizmo.hovered_handle)
            t := closest_t_on_line_to_ray(ray_origin, ray_direction, position, direction)

            if abs(t) > glm.F32_EPSILON {
                gizmo.dragging_handle = gizmo.hovered_handle
                gizmo.drag_origin = position
                gizmo.drag_start_point = position + direction * t
            }
        }
    } else if released {
        gizmo.dragging_handle = .None
    } else {
        direction := gizmo_axis_direction(gizmo.dragging_handle)
        start_t := glm.dot(gizmo.drag_start_point - gizmo.drag_origin, direction)
        t := closest_t_on_line_to_ray(ray_origin, ray_direction, gizmo.drag_origin, direction)

        origin = gizmo.drag_origin
        axis = direction
        factor = max(t / start_t, 0.01)
        active = true
    }

    gizmo_draw_scale(position, scale)

    return origin, axis, factor, active
}

gizmo_is_hovered :: proc() -> bool {
    return gizmo.hovered_handle != .None
}

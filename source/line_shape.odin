package imdd3

import glm "core:math/linalg/glsl"

DEBUG_SHAPE_CAP :: 256

Shape_Type :: enum {
    Box,
    Cylinder,
    Cone,
    Sphere,
}

Debug_Shape :: struct {
    translation: glm.vec3,
    rotation: glm.quat,
    scale: glm.vec3,
    color: u32,
}

push_shape :: proc(type: Shape_Type) -> ^Debug_Shape {
    shape := &state.shape_data[type][state.shape_data_len[type]]
    state.shape_data_len[type] = (state.shape_data_len[type] + 1) % DEBUG_SHAPE_CAP
    return shape
}

debug_aabb :: proc(position: glm.vec3, size: glm.vec3, color: u32) {
    shape := push_shape(.Box)
    shape.translation = position
    shape.rotation = {}
    shape.scale = size / 2
    shape.color = color
}

debug_aabb_bounds :: proc(min: glm.vec3, max: glm.vec3, color: u32) {
    shape := push_shape(.Box)
    shape.translation = (min + max) / 2
    shape.rotation = {}
    shape.scale = glm.abs(max - min) / 2
    shape.color = color
}

debug_obb :: proc(position: glm.vec3, size: glm.vec3, rotation: glm.vec3, color: u32) {
    shape := push_shape(.Box)
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = size / 2
    shape.color = color
}

debug_cylinder_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32) {
    shape := push_shape(.Cylinder)
    shape.translation = position
    shape.rotation = {}
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
}

debug_cylinder_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32) {
    shape := push_shape(.Cylinder)
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
}

debug_cylinder_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32) {
    height := glm.distance(start, end) / 2

    shape := push_shape(.Cylinder)
    shape.translation = (start + end) / 2
    shape.rotation = quat_rotation_dir(glm.normalize(end - start))
    shape.scale = {radius, height, radius}
    shape.color = color
}

debug_cone_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32) {
    shape := push_shape(.Cone)
    shape.translation = position
    shape.rotation = {}
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
}

debug_cone_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32) {
    shape := push_shape(.Cone)
    shape.translation = position
    shape.rotation = quat_rotation_xyz(rotation)
    shape.scale = {size.x, size.y / 2, size.x}
    shape.color = color
}

debug_cone_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32) {
    height := glm.distance(start, end) / 2

    shape := push_shape(.Cone)
    shape.translation = (start + end) / 2
    shape.rotation = quat_rotation_dir(glm.normalize(start - end))
    shape.scale = {radius, height, radius}
    shape.color = color
}

debug_sphere :: proc(position: glm.vec3, radius: f32, color: u32) {
    shape := push_shape(.Sphere)
    shape.translation = position
    shape.rotation = {}
    shape.scale = {radius, radius, radius}
    shape.color = color
}

// rendering
init_shape_rdr :: proc() {
    vertices: [dynamic]glm.vec3; defer delete(vertices)
    indices: [dynamic]u32; defer delete(indices)

    offset: [Shape_Type]Index_Offset
    offset[.Box] = geometry_lines_box(&vertices, &indices, {1, 1, 1})
    offset[.Cylinder] = geometry_lines_cylinder(&vertices, &indices, {1, 1}, 16)
    offset[.Cone] = geometry_lines_cone(&vertices, &indices, {1, 1}, 16)
    offset[.Sphere] = geometry_lines_sphere(&vertices, &indices, 1, 16)

    for type in Shape_Type {
        state.shape_data[type] = make([dynamic]Debug_Shape, DEBUG_SHAPE_CAP, DEBUG_SHAPE_CAP)
    }

    state.renderer.shape_init(vertices[:], indices[:], offset)
}

free_shape_rdr :: proc() {
    for type in Shape_Type {
        delete(state.shape_data[type])
    }

    state.renderer.shape_destroy()
}

render_shape_rdr :: proc(resolution: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    data: [Shape_Type][]Debug_Shape

    for type in Shape_Type {
        data[type] = state.shape_data[type][:state.shape_data_len[type]]
    }

    state.renderer.shape_render(data, resolution, projection, view)

    for type in Shape_Type {
        state.shape_data_len[type] = 0
    }
}

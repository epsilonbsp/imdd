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

Index_Offset :: struct {
    pos: u32,
    len: i32,
}

geometry_lines_box :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec3) -> (offset: Index_Offset) {
    offset.pos = cast(u32) len(indices)

    index := u32(len(vertices))

    append(vertices,
        glm.vec3{-size.x, -size.y,  size.z},
        glm.vec3{ size.x, -size.y,  size.z},
        glm.vec3{ size.x,  size.y,  size.z},
        glm.vec3{-size.x,  size.y,  size.z},
        glm.vec3{ size.x, -size.y, -size.z},
        glm.vec3{-size.x, -size.y, -size.z},
        glm.vec3{-size.x,  size.y, -size.z},
        glm.vec3{ size.x,  size.y, -size.z},
    )

    append(indices,
        index,     index + 1,
        index + 1, index + 2,
        index + 2, index + 3,
        index + 3, index + 0,

        index + 4, index + 5,
        index + 5, index + 6,
        index + 6, index + 7,
        index + 7, index + 4,

        index + 5, index + 0,
        index + 6, index + 3,

        index + 1, index + 4,
        index + 2, index + 7
    )

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_cylinder :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(u32) len(indices)

    angle := glm.PI * 2 / f32(segments)
    index := u32(len(vertices))

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, -size.y, z * size.x})
    }

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, size.y, z * size.x})
    }

    for i: u32 = 0; i < u32(segments); i += 1 {
        append(indices, index + i, index + (i + 1) % u32(segments))
        append(indices, index + u32(segments) + i, index + u32(segments) + (i + 1) % u32(segments))
        append(indices, index + i, index + u32(segments) + i)
    }

    half := u32(segments / 2)
    quarter := u32(segments / 4)
    top_start := index + u32(segments)

    append(indices, index + 0, index + half)
    append(indices, index + quarter, index + quarter + half)

    append(indices, top_start + 0, top_start + half)
    append(indices, top_start + quarter, top_start + quarter + half)

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_cone :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(u32) len(indices)

    angle := glm.PI * 2 / f32(segments)
    index := u32(len(vertices))

    for i in 0 ..< segments {
        x, z: f32 = glm.cos(angle * f32(i)), glm.sin(angle * f32(i))

        append(vertices, glm.vec3{x * size.x, -size.y, z * size.x})
    }

    append(vertices, glm.vec3{0, size.y, 0})

    for i: u32 = 0; i < u32(segments); i += 1 {
        append(indices, index + i, index + (i + 1) % u32(segments))
        append(indices, index + i, index + u32(segments) )
    }

    half := u32(segments / 2)
    quarter := u32(segments / 4)

    append(indices, index + 0, index + half)
    append(indices, index + quarter, index + quarter + half)

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
}

geometry_lines_sphere :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, radius: f32, segments: i32) -> (offset: Index_Offset) {
    offset.pos = cast(u32) len(indices)

    rings := segments / 2
    start_index := u32(len(vertices))
    first_ring_start := start_index + 1

    append(vertices, glm.vec3{0, radius, 0})

    for lat in 1 ..< rings {
        theta := glm.PI * f32(lat) / f32(rings)
        y := radius * glm.cos(theta)
        r := radius * glm.sin(theta)

        for lon in 0 ..< segments {
            phi := 2.0 * glm.PI * f32(lon) / f32(segments)
            x := r * glm.cos(phi)
            z := r * glm.sin(phi)

            append(vertices, glm.vec3{x, y, z})
        }
    }

    num_mid_rings := u32(glm.max(0, rings - 1))
    bottom_index := first_ring_start + num_mid_rings * u32(segments)

    append(vertices, glm.vec3{0, -radius, 0})

    for lat: u32 = 0; lat < num_mid_rings; lat += 1 {
        row_start := first_ring_start + lat * u32(segments)

        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            next_lon := (lon + 1) % u32(segments)
            append(indices, row_start + lon, row_start + next_lon)
        }
    }

    if num_mid_rings > 0 {
        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            append(indices, start_index, first_ring_start + lon)
        }
    }

    if num_mid_rings >= 2 {
        for lat: u32 = 0; lat + 1 < num_mid_rings; lat += 1 {
            row0 := first_ring_start + lat * u32(segments)
            row1 := row0 + u32(segments)

            for lon: u32 = 0; lon < u32(segments); lon += 1 {
                append(indices, row0 + lon, row1 + lon)
            }
        }
    }

    if num_mid_rings > 0 {
        last_ring_start := bottom_index - u32(segments)

        for lon: u32 = 0; lon < u32(segments); lon += 1 {
            append(indices, last_ring_start + lon, bottom_index)
        }
    } else {
        append(indices, start_index, bottom_index)
    }

    offset.len = cast(i32) len(indices) - i32(offset.pos)

    return offset
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

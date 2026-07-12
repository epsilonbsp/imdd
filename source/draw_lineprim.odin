package imdd3

import glm "core:math/linalg/glsl"

LINEPRIM_CAP :: 256

Lineprim_Type :: enum {
    Box,
    Cylinder,
    Cone,
    Sphere,
}

Lineprim_Instance :: struct {
    translation: glm.vec3,
    rotation: glm.quat,
    scale: glm.vec3,
    color: u32,
}

Lineprim_Range :: struct {
    first: u32,
    count: i32,
}

Lineprim_State :: struct {
    instances: [Lineprim_Type][dynamic]Lineprim_Instance,
    counts: [Lineprim_Type]i32,
}

lineprim_state: Lineprim_State

lineprim_init :: proc() {
    vertices: [dynamic]glm.vec3; defer delete(vertices)
    indices: [dynamic]u32; defer delete(indices)

    ranges: [Lineprim_Type]Lineprim_Range
    ranges[.Box] = lineprim_generate_box(&vertices, &indices, {1, 1, 1})
    ranges[.Cylinder] = lineprim_generate_cylinder(&vertices, &indices, {1, 1}, 16)
    ranges[.Cone] = lineprim_generate_cone(&vertices, &indices, {1, 1}, 16)
    ranges[.Sphere] = lineprim_generate_sphere(&vertices, &indices, 1, 16)

    for type in Lineprim_Type {
        lineprim_state.instances[type] = make([dynamic]Lineprim_Instance, LINEPRIM_CAP, LINEPRIM_CAP)
    }

    state.renderer.lineprim_init(vertices[:], indices[:], ranges)
}

lineprim_destroy :: proc() {
    for type in Lineprim_Type {
        delete(lineprim_state.instances[type])
    }

    state.renderer.lineprim_destroy()
}

lineprim_render :: proc(resolution: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    data: [Lineprim_Type][]Lineprim_Instance

    for type in Lineprim_Type {
        data[type] = lineprim_state.instances[type][:lineprim_state.counts[type]]
    }

    state.renderer.lineprim_render(data, resolution, projection, view)

    for type in Lineprim_Type {
        lineprim_state.counts[type] = 0
    }
}

lineprim_generate_box :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec3) -> (range: Lineprim_Range) {
    range.first = cast(u32) len(indices)

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

    range.count = cast(i32) len(indices) - i32(range.first)

    return range
}

lineprim_generate_cylinder :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (range: Lineprim_Range) {
    range.first = cast(u32) len(indices)

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

    range.count = cast(i32) len(indices) - i32(range.first)

    return range
}

lineprim_generate_cone :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, size: glm.vec2, segments: i32) -> (range: Lineprim_Range) {
    range.first = cast(u32) len(indices)

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

    range.count = cast(i32) len(indices) - i32(range.first)

    return range
}

lineprim_generate_sphere :: proc(vertices: ^[dynamic]glm.vec3, indices: ^[dynamic]u32, radius: f32, segments: i32) -> (range: Lineprim_Range) {
    range.first = cast(u32) len(indices)

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

    range.count = cast(i32) len(indices) - i32(range.first)

    return range
}

lineprim_push :: proc(type: Lineprim_Type) -> ^Lineprim_Instance {
    instance := &lineprim_state.instances[type][lineprim_state.counts[type]]
    lineprim_state.counts[type] = (lineprim_state.counts[type] + 1) % LINEPRIM_CAP
    return instance
}

draw_lineprim_aabb :: proc(position: glm.vec3, size: glm.vec3, color: u32) {
    instance := lineprim_push(.Box)
    instance.translation = position
    instance.rotation = {}
    instance.scale = size / 2
    instance.color = color
}

draw_lineprim_aabb_bounds :: proc(min: glm.vec3, max: glm.vec3, color: u32) {
    instance := lineprim_push(.Box)
    instance.translation = (min + max) / 2
    instance.rotation = {}
    instance.scale = glm.abs(max - min) / 2
    instance.color = color
}

draw_lineprim_obb :: proc(position: glm.vec3, size: glm.vec3, rotation: glm.vec3, color: u32) {
    instance := lineprim_push(.Box)
    instance.translation = position
    instance.rotation = quat_rotation_xyz(rotation)
    instance.scale = size / 2
    instance.color = color
}

draw_lineprim_cylinder_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32) {
    instance := lineprim_push(.Cylinder)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
}

draw_lineprim_cylinder_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32) {
    instance := lineprim_push(.Cylinder)
    instance.translation = position
    instance.rotation = quat_rotation_xyz(rotation)
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
}

draw_lineprim_cylinder_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32) {
    height := glm.distance(start, end) / 2

    instance := lineprim_push(.Cylinder)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(end - start))
    instance.scale = {radius, height, radius}
    instance.color = color
}

draw_lineprim_cone_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32) {
    instance := lineprim_push(.Cone)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
}

draw_lineprim_cone_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32) {
    instance := lineprim_push(.Cone)
    instance.translation = position
    instance.rotation = quat_rotation_xyz(rotation)
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
}

draw_lineprim_cone_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32) {
    height := glm.distance(start, end) / 2

    instance := lineprim_push(.Cone)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(start - end))
    instance.scale = {radius, height, radius}
    instance.color = color
}

draw_lineprim_sphere :: proc(position: glm.vec3, radius: f32, color: u32) {
    instance := lineprim_push(.Sphere)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {radius, radius, radius}
    instance.color = color
}

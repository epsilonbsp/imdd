package imdd3

PRIMITIVE_CAP :: 256

Primitive_Vertex :: struct {
    position: [3]f32,
    normal: [3]f32,
}

Primitive_Type :: enum {
    Box,
}

Primitive_Range :: struct {
    first: u32,
    count: i32,
}

Primitive_Instance :: struct {
    translation: [3]f32,
    rotation: quaternion128,
    scale: [3]f32,
    color: u32,
}

Primitive_Renderer :: struct {
    instances: [Primitive_Type][dynamic]Primitive_Instance,
    counts: [Primitive_Type]i32,
}

primitive_renderer: Primitive_Renderer

primitive_generate_box :: proc(vertices: ^[dynamic]Primitive_Vertex, indices: ^[dynamic]u32) -> (range: Primitive_Range) {
    range.first = u32(len(indices))

    index := u32(len(vertices))

    append(vertices,
        // Left
        Primitive_Vertex{{-0.5, -0.5, -0.5}, {-1, 0, 0}},
        Primitive_Vertex{{-0.5, -0.5,  0.5}, {-1, 0, 0}},
        Primitive_Vertex{{-0.5,  0.5,  0.5}, {-1, 0, 0}},
        Primitive_Vertex{{-0.5,  0.5, -0.5}, {-1, 0, 0}},

        // Right
        Primitive_Vertex{{ 0.5, -0.5,  0.5}, {1, 0, 0}},
        Primitive_Vertex{{ 0.5, -0.5, -0.5}, {1, 0, 0}},
        Primitive_Vertex{{ 0.5,  0.5, -0.5}, {1, 0, 0}},
        Primitive_Vertex{{ 0.5,  0.5,  0.5}, {1, 0, 0}},

        // Bottom
        Primitive_Vertex{{-0.5, -0.5, -0.5}, {0, -1, 0}},
        Primitive_Vertex{{ 0.5, -0.5, -0.5}, {0, -1, 0}},
        Primitive_Vertex{{ 0.5, -0.5,  0.5}, {0, -1, 0}},
        Primitive_Vertex{{-0.5, -0.5,  0.5}, {0, -1, 0}},

        // Top
        Primitive_Vertex{{-0.5,  0.5,  0.5}, {0, 1, 0}},
        Primitive_Vertex{{ 0.5,  0.5,  0.5}, {0, 1, 0}},
        Primitive_Vertex{{ 0.5,  0.5, -0.5}, {0, 1, 0}},
        Primitive_Vertex{{-0.5,  0.5, -0.5}, {0, 1, 0}},

        // Back
        Primitive_Vertex{{-0.5, -0.5,  0.5}, {0, 0, 1}},
        Primitive_Vertex{{ 0.5, -0.5,  0.5}, {0, 0, 1}},
        Primitive_Vertex{{ 0.5,  0.5,  0.5}, {0, 0, 1}},
        Primitive_Vertex{{-0.5,  0.5,  0.5}, {0, 0, 1}},

        // Front
        Primitive_Vertex{{ 0.5, -0.5, -0.5}, {0, 0, -1}},
        Primitive_Vertex{{-0.5, -0.5, -0.5}, {0, 0, -1}},
        Primitive_Vertex{{-0.5,  0.5, -0.5}, {0, 0, -1}},
        Primitive_Vertex{{ 0.5,  0.5, -0.5}, {0, 0, -1}},
    )

    for face in 0 ..< 6 {
        base := index + u32(face) * 4

        append(indices,
            base + 0, base + 1, base + 2,
            base + 0, base + 2, base + 3,
        )
    }

    range.count = i32(len(indices)) - i32(range.first)

    return range
}

primitive_renderer_init :: proc() {
    vertices: [dynamic]Primitive_Vertex; defer delete(vertices)
    indices: [dynamic]u32; defer delete(indices)

    ranges: [Primitive_Type]Primitive_Range
    ranges[.Box] = primitive_generate_box(&vertices, &indices)

    for type in Primitive_Type {
        primitive_renderer.instances[type] = make([dynamic]Primitive_Instance, PRIMITIVE_CAP, PRIMITIVE_CAP)
    }

    state.renderer.primitive_renderer_init(vertices[:], indices[:], ranges)
}

primitive_renderer_destroy :: proc() {
    for type in Primitive_Type {
        delete(primitive_renderer.instances[type])
    }

    state.renderer.primitive_renderer_destroy()
}

primitive_renderer_render :: proc(viewport: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    data: [Primitive_Type][]Primitive_Instance

    for type in Primitive_Type {
        data[type] = primitive_renderer.instances[type][:primitive_renderer.counts[type]]
    }

    state.renderer.primitive_renderer_render(data, viewport, projection, view)

    for type in Primitive_Type {
        primitive_renderer.counts[type] = 0
    }
}

primitive_push :: proc(type: Primitive_Type) -> ^Primitive_Instance {
    instance := &primitive_renderer.instances[type][primitive_renderer.counts[type]]
    primitive_renderer.counts[type] = (primitive_renderer.counts[type] + 1) % PRIMITIVE_CAP

    return instance
}

primitive_aabb :: proc(position: [3]f32, size: [3]f32, color: u32) {
    instance := primitive_push(.Box)
    instance.translation = position
    instance.rotation = {}
    instance.scale = size
    instance.color = color
}
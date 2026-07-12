package imdd3

TRIPRIM_CAP :: 256

Triprim_Vertex :: struct {
    position: [3]f32,
    normal: [3]f32,
}

Triprim_Type :: enum {
    Box,
}

Triprim_Range :: struct {
    first: u32,
    count: i32,
}

Triprim_Instance :: struct {
    translation: [3]f32,
    rotation: quaternion128,
    scale: [3]f32,
    color: u32,
}

Triprim_State :: struct {
    instances: [Triprim_Type][dynamic]Triprim_Instance,
    counts: [Triprim_Type]i32,
}

triprim_state: Triprim_State

triprim_init :: proc() {
    vertices: [dynamic]Triprim_Vertex; defer delete(vertices)
    indices: [dynamic]u32; defer delete(indices)

    ranges: [Triprim_Type]Triprim_Range
    ranges[.Box] = triprim_generate_box(&vertices, &indices)

    for type in Triprim_Type {
        triprim_state.instances[type] = make([dynamic]Triprim_Instance, TRIPRIM_CAP, TRIPRIM_CAP)
    }

    state.renderer.triprim_init(vertices[:], indices[:], ranges)
}

triprim_destroy :: proc() {
    for type in Triprim_Type {
        delete(triprim_state.instances[type])
    }

    state.renderer.triprim_destroy()
}

triprim_render :: proc(viewport: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    data: [Triprim_Type][]Triprim_Instance

    for type in Triprim_Type {
        data[type] = triprim_state.instances[type][:triprim_state.counts[type]]
    }

    state.renderer.triprim_render(data, viewport, projection, view)

    for type in Triprim_Type {
        triprim_state.counts[type] = 0
    }
}

triprim_generate_box :: proc(vertices: ^[dynamic]Triprim_Vertex, indices: ^[dynamic]u32) -> (range: Triprim_Range) {
    range.first = u32(len(indices))

    index := u32(len(vertices))

    append(vertices,
        // Left
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {-1, 0, 0}},
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {-1, 0, 0}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {-1, 0, 0}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {-1, 0, 0}},

        // Right
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {1, 0, 0}},
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {1, 0, 0}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {1, 0, 0}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {1, 0, 0}},

        // Bottom
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {0, -1, 0}},
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {0, -1, 0}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {0, -1, 0}},
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {0, -1, 0}},

        // Top
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {0, 1, 0}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {0, 1, 0}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {0, 1, 0}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {0, 1, 0}},

        // Back
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {0, 0, 1}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {0, 0, 1}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {0, 0, 1}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {0, 0, 1}},

        // Front
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {0, 0, -1}},
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {0, 0, -1}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {0, 0, -1}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {0, 0, -1}},
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

triprim_push :: proc(type: Triprim_Type) -> ^Triprim_Instance {
    instance := &triprim_state.instances[type][triprim_state.counts[type]]
    triprim_state.counts[type] = (triprim_state.counts[type] + 1) % TRIPRIM_CAP

    return instance
}

draw_triprim_aabb :: proc(position: [3]f32, size: [3]f32, color: u32) {
    instance := triprim_push(.Box)
    instance.translation = position
    instance.rotation = {}
    instance.scale = size
    instance.color = color
}

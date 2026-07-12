package imdd3

TRIPRIM_CAP :: 256

Triprim_Vertex :: struct {
    anchor: [3]f32,
    direction: [3]f32,
    normal: [3]f32,
    barycentric: [3]f32,
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
    radius: f32,
    color: u32,
}

Triprim_State :: struct {
    instances: [Triprim_Type][dynamic]Triprim_Instance,
    counts: [Triprim_Type]i32,
}

triprim_state: Triprim_State

triprim_init :: proc() {
    vertices: [dynamic]Triprim_Vertex; defer delete(vertices)

    ranges: [Triprim_Type]Triprim_Range
    ranges[.Box] = triprim_generate_box(&vertices)

    for type in Triprim_Type {
        triprim_state.instances[type] = make([dynamic]Triprim_Instance, TRIPRIM_CAP, TRIPRIM_CAP)
    }

    renderer.interface.triprim_init(vertices[:], ranges)
}

triprim_destroy :: proc() {
    for type in Triprim_Type {
        delete(triprim_state.instances[type])
    }
}

triprim_render :: proc() {
    data: [Triprim_Type][]Triprim_Instance

    for type in Triprim_Type {
        data[type] = triprim_state.instances[type][:triprim_state.counts[type]]
    }

    renderer.interface.triprim_render(data)

    for type in Triprim_Type {
        triprim_state.counts[type] = 0
    }
}

triprim_generate_box :: proc(vertices: ^[dynamic]Triprim_Vertex) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    append(vertices,
        // Left
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {}, {-1, 0, 0}, {1, 1, 0}},
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {}, {-1, 0, 0}, {0, 2, 0}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {}, {-1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {}, {-1, 0, 0}, {1, 0, 1}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {}, {-1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {}, {-1, 0, 0}, {0, 0, 2}},

        // Right
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {}, {1, 0, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {}, {1, 0, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {}, {1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {}, {1, 0, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {}, {1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {}, {1, 0, 0}, {0, 0, 2}},

        // Bottom
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {}, {0, -1, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {}, {0, -1, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {}, {0, -1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {}, {0, -1, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {}, {0, -1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {}, {0, -1, 0}, {0, 0, 2}},

        // Top
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {}, {0, 1, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {}, {0, 1, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {}, {0, 1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {}, {0, 1, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {}, {0, 1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {}, {0, 1, 0}, {0, 0, 2}},

        // Back
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {}, {0, 0, 1}, {1, 1, 0}},
        Triprim_Vertex{{ 0.5, -0.5,  0.5}, {}, {0, 0, 1}, {0, 2, 0}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {}, {0, 0, 1}, {0, 1, 1}},
        Triprim_Vertex{{-0.5, -0.5,  0.5}, {}, {0, 0, 1}, {1, 0, 1}},
        Triprim_Vertex{{ 0.5,  0.5,  0.5}, {}, {0, 0, 1}, {0, 1, 1}},
        Triprim_Vertex{{-0.5,  0.5,  0.5}, {}, {0, 0, 1}, {0, 0, 2}},

        // Front
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {}, {0, 0, -1}, {1, 1, 0}},
        Triprim_Vertex{{-0.5, -0.5, -0.5}, {}, {0, 0, -1}, {0, 2, 0}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {}, {0, 0, -1}, {0, 1, 1}},
        Triprim_Vertex{{ 0.5, -0.5, -0.5}, {}, {0, 0, -1}, {1, 0, 1}},
        Triprim_Vertex{{-0.5,  0.5, -0.5}, {}, {0, 0, -1}, {0, 1, 1}},
        Triprim_Vertex{{ 0.5,  0.5, -0.5}, {}, {0, 0, -1}, {0, 0, 2}},
    )

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_push :: proc(type: Triprim_Type) -> ^Triprim_Instance {
    instance := &triprim_state.instances[type][triprim_state.counts[type]]
    triprim_state.counts[type] = (triprim_state.counts[type] + 1) % TRIPRIM_CAP

    return instance
}

// API
draw_aabb :: proc(position: [3]f32, size: [3]f32, color: u32) {
    instance := triprim_push(.Box)
    instance.translation = position
    instance.rotation = {}
    instance.scale = size
    instance.color = color
}

package imdd3

import glm "core:math/linalg/glsl"

TRIPRIM_CAP :: 256

Triprim_Vertex :: struct {
    anchor: [3]f32,
    direction: [3]f32,
    normal: [3]f32,
    barycentric: [3]f32,
}

Triprim_Type :: enum {
    Box,
    Cylinder,
    Cone,
    Cone_Frustum,
    Sphere,
    Capsule,
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
    wire_color: u32,
}

Triprim_State :: struct {
    instances: [Triprim_Type][dynamic]Triprim_Instance,
}

triprim_state: Triprim_State

triprim_init :: proc() {
    vertices: [dynamic]Triprim_Vertex; defer delete(vertices)

    ranges: [Triprim_Type]Triprim_Range
    ranges[.Box] = triprim_generate_box(&vertices)
    ranges[.Cylinder] = triprim_generate_cylinder(&vertices, 16)
    ranges[.Cone] = triprim_generate_cone(&vertices, 16)
    ranges[.Cone_Frustum] = triprim_generate_cone_frustum(&vertices, 16)
    ranges[.Sphere] = triprim_generate_sphere(&vertices, 16)
    ranges[.Capsule] = triprim_generate_capsule(&vertices, 16)

    for type in Triprim_Type {
        triprim_state.instances[type] = make([dynamic]Triprim_Instance, 0, TRIPRIM_CAP)
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
        data[type] = triprim_state.instances[type][:]
    }

    renderer.interface.triprim_render(data)

    for type in Triprim_Type {
        clear(&triprim_state.instances[type])
    }
}

triprim_generate_box :: proc(vertices: ^[dynamic]Triprim_Vertex) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    append(vertices,
        // Left
        Triprim_Vertex{{-1, -1, -1}, {}, {-1, 0, 0}, {1, 1, 0}},
        Triprim_Vertex{{-1, -1,  1}, {}, {-1, 0, 0}, {0, 2, 0}},
        Triprim_Vertex{{-1,  1,  1}, {}, {-1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1, -1, -1}, {}, {-1, 0, 0}, {1, 0, 1}},
        Triprim_Vertex{{-1,  1,  1}, {}, {-1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1,  1, -1}, {}, {-1, 0, 0}, {0, 0, 2}},

        // Right
        Triprim_Vertex{{ 1, -1,  1}, {}, {1, 0, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 1, -1, -1}, {}, {1, 0, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 1,  1, -1}, {}, {1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{ 1, -1,  1}, {}, {1, 0, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 1,  1, -1}, {}, {1, 0, 0}, {0, 1, 1}},
        Triprim_Vertex{{ 1,  1,  1}, {}, {1, 0, 0}, {0, 0, 2}},

        // Bottom
        Triprim_Vertex{{-1, -1, -1}, {}, {0, -1, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 1, -1, -1}, {}, {0, -1, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 1, -1,  1}, {}, {0, -1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1, -1, -1}, {}, {0, -1, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 1, -1,  1}, {}, {0, -1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1, -1,  1}, {}, {0, -1, 0}, {0, 0, 2}},

        // Top
        Triprim_Vertex{{-1,  1,  1}, {}, {0, 1, 0}, {1, 1, 0}},
        Triprim_Vertex{{ 1,  1,  1}, {}, {0, 1, 0}, {0, 2, 0}},
        Triprim_Vertex{{ 1,  1, -1}, {}, {0, 1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1,  1,  1}, {}, {0, 1, 0}, {1, 0, 1}},
        Triprim_Vertex{{ 1,  1, -1}, {}, {0, 1, 0}, {0, 1, 1}},
        Triprim_Vertex{{-1,  1, -1}, {}, {0, 1, 0}, {0, 0, 2}},

        // Back
        Triprim_Vertex{{-1, -1,  1}, {}, {0, 0, 1}, {1, 1, 0}},
        Triprim_Vertex{{ 1, -1,  1}, {}, {0, 0, 1}, {0, 2, 0}},
        Triprim_Vertex{{ 1,  1,  1}, {}, {0, 0, 1}, {0, 1, 1}},
        Triprim_Vertex{{-1, -1,  1}, {}, {0, 0, 1}, {1, 0, 1}},
        Triprim_Vertex{{ 1,  1,  1}, {}, {0, 0, 1}, {0, 1, 1}},
        Triprim_Vertex{{-1,  1,  1}, {}, {0, 0, 1}, {0, 0, 2}},

        // Front
        Triprim_Vertex{{ 1, -1, -1}, {}, {0, 0, -1}, {1, 1, 0}},
        Triprim_Vertex{{-1, -1, -1}, {}, {0, 0, -1}, {0, 2, 0}},
        Triprim_Vertex{{-1,  1, -1}, {}, {0, 0, -1}, {0, 1, 1}},
        Triprim_Vertex{{ 1, -1, -1}, {}, {0, 0, -1}, {1, 0, 1}},
        Triprim_Vertex{{-1,  1, -1}, {}, {0, 0, -1}, {0, 1, 1}},
        Triprim_Vertex{{ 1,  1, -1}, {}, {0, 0, -1}, {0, 0, 2}},
    )

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_generate_cylinder :: proc(vertices: ^[dynamic]Triprim_Vertex, segments: i32) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    angle := glm.PI * 2 / f32(segments)

    // Side
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        n0 := [3]f32{x0, 0, z0}
        n1 := [3]f32{x1, 0, z1}

        bottom0 := [3]f32{x0, -1, z0}
        bottom1 := [3]f32{x1, -1, z1}
        top0 := [3]f32{x0, 1, z0}
        top1 := [3]f32{x1, 1, z1}

        append(vertices,
            Triprim_Vertex{bottom0, {}, n0, {1, 1, 0}},
            Triprim_Vertex{top1,    {}, n1, {0, 1, 1}},
            Triprim_Vertex{bottom1, {}, n1, {0, 2, 0}},

            Triprim_Vertex{bottom0, {}, n0, {1, 0, 1}},
            Triprim_Vertex{top0,    {}, n0, {0, 0, 2}},
            Triprim_Vertex{top1,    {}, n1, {0, 1, 1}},
        )
    }

    // Bottom cap
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        append(vertices,
            Triprim_Vertex{{0, -1, 0}, {}, {0, -1, 0}, {1, 1, 1}},
            Triprim_Vertex{{x0, -1, z0}, {}, {0, -1, 0}, {0, 2, 1}},
            Triprim_Vertex{{x1, -1, z1}, {}, {0, -1, 0}, {0, 1, 2}},
        )
    }

    // Top cap
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        append(vertices,
            Triprim_Vertex{{0, 1, 0}, {}, {0, 1, 0}, {1, 1, 1}},
            Triprim_Vertex{{x1, 1, z1}, {}, {0, 1, 0}, {0, 2, 1}},
            Triprim_Vertex{{x0, 1, z0}, {}, {0, 1, 0}, {0, 1, 2}},
        )
    }

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_generate_cone :: proc(vertices: ^[dynamic]Triprim_Vertex, segments: i32) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    angle := glm.PI * 2 / f32(segments)

    // Side
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        n0 := glm.normalize([3]f32{x0, 1, z0})
        n1 := glm.normalize([3]f32{x1, 1, z1})
        n_apex := glm.normalize(n0 + n1)

        append(vertices,
            Triprim_Vertex{{x0, -1, z0}, {}, n0, {1, 0, 0}},
            Triprim_Vertex{{0, 1, 0}, {}, n_apex, {0, 0, 1}},
            Triprim_Vertex{{x1, -1, z1}, {}, n1, {0, 1, 0}},
        )
    }

    // Bottom cap
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        append(vertices,
            Triprim_Vertex{{0, -1, 0}, {}, {0, -1, 0}, {1, 1, 1}},
            Triprim_Vertex{{x0, -1, z0}, {}, {0, -1, 0}, {0, 2, 1}},
            Triprim_Vertex{{x1, -1, z1}, {}, {0, -1, 0}, {0, 1, 2}},
        )
    }

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_generate_cone_frustum :: proc(vertices: ^[dynamic]Triprim_Vertex, segments: i32) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    angle := glm.PI * 2 / f32(segments)

    // Side
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        n0 := [3]f32{x0, 0, z0}
        n1 := [3]f32{x1, 0, z1}

        bottom0 := [3]f32{x0, -1, z0}
        bottom1 := [3]f32{x1, -1, z1}

        append(vertices,
            Triprim_Vertex{bottom0, {}, n0, {1, 1, 0}},
            Triprim_Vertex{{0, 1, 0}, n1, n1, {0, 1, 1}},
            Triprim_Vertex{bottom1, {}, n1, {0, 2, 0}},

            Triprim_Vertex{bottom0, {}, n0, {1, 0, 1}},
            Triprim_Vertex{{0, 1, 0}, n0, n0, {0, 0, 2}},
            Triprim_Vertex{{0, 1, 0}, n1, n1, {0, 1, 1}},
        )
    }

    // Bottom cap
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        append(vertices,
            Triprim_Vertex{{0, -1, 0}, {}, {0, -1, 0}, {1, 1, 1}},
            Triprim_Vertex{{x0, -1, z0}, {}, {0, -1, 0}, {0, 2, 1}},
            Triprim_Vertex{{x1, -1, z1}, {}, {0, -1, 0}, {0, 1, 2}},
        )
    }

    // Top cap
    for i in 0 ..< segments {
        a0 := angle * f32(i)
        a1 := angle * f32(i + 1)

        x0, z0 := glm.cos(a0), glm.sin(a0)
        x1, z1 := glm.cos(a1), glm.sin(a1)

        append(vertices,
            Triprim_Vertex{{0, 1, 0}, {}, {0, 1, 0}, {1, 1, 1}},
            Triprim_Vertex{{0, 1, 0}, {x1, 0, z1}, {0, 1, 0}, {0, 2, 1}},
            Triprim_Vertex{{0, 1, 0}, {x0, 0, z0}, {0, 1, 0}, {0, 1, 2}},
        )
    }

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_generate_sphere :: proc(vertices: ^[dynamic]Triprim_Vertex, segments: i32) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    rings := segments / 2

    // Top cap
    for lon in 0 ..< segments {
        theta := glm.PI / f32(rings)
        y := glm.cos(theta)
        r := glm.sin(theta)

        phi0 := 2.0 * glm.PI * f32(lon) / f32(segments)
        phi1 := 2.0 * glm.PI * f32(lon + 1) / f32(segments)

        p0 := [3]f32{r * glm.cos(phi0), y, r * glm.sin(phi0)}
        p1 := [3]f32{r * glm.cos(phi1), y, r * glm.sin(phi1)}

        append(vertices,
            Triprim_Vertex{{0, 1, 0}, {}, {0, 1, 0}, {1, 0, 0}},
            Triprim_Vertex{p1, {}, p1, {0, 1, 0}},
            Triprim_Vertex{p0, {}, p0, {0, 0, 1}},
        )
    }

    // Middle bands
    for lat in 1 ..< rings - 1 {
        theta0 := glm.PI * f32(lat) / f32(rings)
        theta1 := glm.PI * f32(lat + 1) / f32(rings)

        y0, r0 := glm.cos(theta0), glm.sin(theta0)
        y1, r1 := glm.cos(theta1), glm.sin(theta1)

        for lon in 0 ..< segments {
            phi0 := 2.0 * glm.PI * f32(lon) / f32(segments)
            phi1 := 2.0 * glm.PI * f32(lon + 1) / f32(segments)

            p00 := [3]f32{r0 * glm.cos(phi0), y0, r0 * glm.sin(phi0)}
            p01 := [3]f32{r0 * glm.cos(phi1), y0, r0 * glm.sin(phi1)}
            p10 := [3]f32{r1 * glm.cos(phi0), y1, r1 * glm.sin(phi0)}
            p11 := [3]f32{r1 * glm.cos(phi1), y1, r1 * glm.sin(phi1)}

            append(vertices,
                Triprim_Vertex{p00, {}, p00, {1, 1, 0}},
                Triprim_Vertex{p01, {}, p01, {0, 2, 0}},
                Triprim_Vertex{p11, {}, p11, {0, 1, 1}},

                Triprim_Vertex{p00, {}, p00, {1, 0, 1}},
                Triprim_Vertex{p11, {}, p11, {0, 1, 1}},
                Triprim_Vertex{p10, {}, p10, {0, 0, 2}},
            )
        }
    }

    // Bottom cap
    for lon in 0 ..< segments {
        theta := glm.PI * f32(rings - 1) / f32(rings)
        y := glm.cos(theta)
        r := glm.sin(theta)

        phi0 := 2.0 * glm.PI * f32(lon) / f32(segments)
        phi1 := 2.0 * glm.PI * f32(lon + 1) / f32(segments)

        p0 := [3]f32{r * glm.cos(phi0), y, r * glm.sin(phi0)}
        p1 := [3]f32{r * glm.cos(phi1), y, r * glm.sin(phi1)}

        append(vertices,
            Triprim_Vertex{{0, -1, 0}, {}, {0, -1, 0}, {1, 0, 0}},
            Triprim_Vertex{p0, {}, p0, {0, 1, 0}},
            Triprim_Vertex{p1, {}, p1, {0, 0, 1}},
        )
    }

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_generate_capsule :: proc(vertices: ^[dynamic]Triprim_Vertex, segments: i32) -> (range: Triprim_Range) {
    range.first = u32(len(vertices))

    hemi_rings := segments / 4
    angle := glm.PI * 2 / f32(segments)

    // Top fan
    for lon in 0 ..< segments {
        theta := (glm.PI * 0.5) / f32(hemi_rings)
        y := glm.cos(theta)
        r := glm.sin(theta)

        phi0 := angle * f32(lon)
        phi1 := angle * f32(lon + 1)

        d0 := [3]f32{r * glm.cos(phi0), y, r * glm.sin(phi0)}
        d1 := [3]f32{r * glm.cos(phi1), y, r * glm.sin(phi1)}

        append(vertices,
            Triprim_Vertex{{0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {1, 0, 0}},
            Triprim_Vertex{{0, 1, 0}, d1, d1, {0, 1, 0}},
            Triprim_Vertex{{0, 1, 0}, d0, d0, {0, 0, 1}},
        )
    }

    // Top bands
    for lat in 1 ..< hemi_rings {
        theta0 := (glm.PI * 0.5) * f32(lat) / f32(hemi_rings)
        theta1 := (glm.PI * 0.5) * f32(lat + 1) / f32(hemi_rings)

        y0, r0 := glm.cos(theta0), glm.sin(theta0)
        y1, r1 := glm.cos(theta1), glm.sin(theta1)

        for lon in 0 ..< segments {
            phi0 := angle * f32(lon)
            phi1 := angle * f32(lon + 1)

            d00 := [3]f32{r0 * glm.cos(phi0), y0, r0 * glm.sin(phi0)}
            d01 := [3]f32{r0 * glm.cos(phi1), y0, r0 * glm.sin(phi1)}
            d10 := [3]f32{r1 * glm.cos(phi0), y1, r1 * glm.sin(phi0)}
            d11 := [3]f32{r1 * glm.cos(phi1), y1, r1 * glm.sin(phi1)}

            append(vertices,
                Triprim_Vertex{{0, 1, 0}, d00, d00, {1, 1, 0}},
                Triprim_Vertex{{0, 1, 0}, d01, d01, {0, 2, 0}},
                Triprim_Vertex{{0, 1, 0}, d11, d11, {0, 1, 1}},

                Triprim_Vertex{{0, 1, 0}, d00, d00, {1, 0, 1}},
                Triprim_Vertex{{0, 1, 0}, d11, d11, {0, 1, 1}},
                Triprim_Vertex{{0, 1, 0}, d10, d10, {0, 0, 2}},
            )
        }
    }

    // Shaft
    for lon in 0 ..< segments {
        phi0 := angle * f32(lon)
        phi1 := angle * f32(lon + 1)

        dir0 := [3]f32{glm.cos(phi0), 0, glm.sin(phi0)}
        dir1 := [3]f32{glm.cos(phi1), 0, glm.sin(phi1)}

        append(vertices,
            Triprim_Vertex{{0, 1, 0}, dir0, dir0, {1, 1, 0}},
            Triprim_Vertex{{0, 1, 0}, dir1, dir1, {0, 2, 0}},
            Triprim_Vertex{{0, -1, 0}, dir1, dir1, {0, 1, 1}},

            Triprim_Vertex{{0, 1, 0}, dir0, dir0, {1, 0, 1}},
            Triprim_Vertex{{0, -1, 0}, dir1, dir1, {0, 1, 1}},
            Triprim_Vertex{{0, -1, 0}, dir0, dir0, {0, 0, 2}},
        )
    }

    // Bottom bands
    for lat in 1 ..< hemi_rings {
        theta0 := (glm.PI * 0.5) * f32(lat) / f32(hemi_rings)
        theta1 := (glm.PI * 0.5) * f32(lat + 1) / f32(hemi_rings)

        y0, r0 := glm.cos(theta0), glm.sin(theta0)
        y1, r1 := glm.cos(theta1), glm.sin(theta1)

        for lon in 0 ..< segments {
            phi0 := angle * f32(lon)
            phi1 := angle * f32(lon + 1)

            d00 := [3]f32{r0 * glm.cos(phi0), -y0, r0 * glm.sin(phi0)}
            d01 := [3]f32{r0 * glm.cos(phi1), -y0, r0 * glm.sin(phi1)}
            d10 := [3]f32{r1 * glm.cos(phi0), -y1, r1 * glm.sin(phi0)}
            d11 := [3]f32{r1 * glm.cos(phi1), -y1, r1 * glm.sin(phi1)}

            append(vertices,
                Triprim_Vertex{{0, -1, 0}, d00, d00, {1, 1, 0}},
                Triprim_Vertex{{0, -1, 0}, d11, d11, {0, 1, 1}},
                Triprim_Vertex{{0, -1, 0}, d01, d01, {0, 2, 0}},

                Triprim_Vertex{{0, -1, 0}, d00, d00, {1, 0, 1}},
                Triprim_Vertex{{0, -1, 0}, d10, d10, {0, 0, 2}},
                Triprim_Vertex{{0, -1, 0}, d11, d11, {0, 1, 1}},
            )
        }
    }

    // Bottom fan
    for lon in 0 ..< segments {
        theta := (glm.PI * 0.5) / f32(hemi_rings)
        y := glm.cos(theta)
        r := glm.sin(theta)

        phi0 := angle * f32(lon)
        phi1 := angle * f32(lon + 1)

        d0 := [3]f32{r * glm.cos(phi0), -y, r * glm.sin(phi0)}
        d1 := [3]f32{r * glm.cos(phi1), -y, r * glm.sin(phi1)}

        append(vertices,
            Triprim_Vertex{{0, -1, 0}, {0, -1, 0}, {0, -1, 0}, {1, 0, 0}},
            Triprim_Vertex{{0, -1, 0}, d0, d0, {0, 1, 0}},
            Triprim_Vertex{{0, -1, 0}, d1, d1, {0, 0, 1}},
        )
    }

    range.count = i32(len(vertices)) - i32(range.first)

    return range
}

triprim_push :: proc(type: Triprim_Type) -> ^Triprim_Instance {
    append(&triprim_state.instances[type], Triprim_Instance{})

    return &triprim_state.instances[type][len(triprim_state.instances[type]) - 1]
}

// API
draw_aabb :: proc(min: [3]f32, max: [3]f32, color: u32) {
    instance := triprim_push(.Box)
    instance.translation = (min + max) / 2
    instance.rotation = {}
    instance.scale = glm.abs(max - min) / 2
    instance.color = color
}

draw_box_aa :: proc(position: [3]f32, size: [3]f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Box)
    instance.translation = position
    instance.rotation = {}
    instance.scale = size / 2
    instance.color = color
    instance.wire_color = wire_color
}

draw_box_o :: proc(position: [3]f32, size: [3]f32, rotation: quaternion128, color: u32) {
    instance := triprim_push(.Box)
    instance.translation = position
    instance.rotation = rotation
    instance.scale = size / 2
    instance.color = color
}

draw_box_ab :: proc(start: [3]f32, end: [3]f32, size: [2]f32, color: u32, wire_color: u32 = 0) {
    height := glm.distance(start, end) / 2

    instance := triprim_push(.Box)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(end - start))
    instance.scale = {size[0] / 2, height, size[1] / 2}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cylinder_aa :: proc(position: [3]f32, size: [2]f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cylinder)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cylinder_o :: proc(position: [3]f32, size: [2]f32, rotation: quaternion128, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cylinder)
    instance.translation = position
    instance.rotation = rotation
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cylinder_ab :: proc(start: [3]f32, end: [3]f32, radius: f32, color: u32, wire_color: u32 = 0) {
    height := glm.distance(start, end) / 2

    instance := triprim_push(.Cylinder)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(end - start))
    instance.scale = {radius, height, radius}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_aa :: proc(position: [3]f32, size: [2]f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cone)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_o :: proc(position: [3]f32, size: [2]f32, rotation: quaternion128, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cone)
    instance.translation = position
    instance.rotation = rotation
    instance.scale = {size.x, size.y / 2, size.x}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_ab :: proc(start: [3]f32, end: [3]f32, radius: f32, color: u32, wire_color: u32 = 0) {
    height := glm.distance(start, end) / 2

    instance := triprim_push(.Cone)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(start - end))
    instance.scale = {radius, height, radius}
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_frustum_aa :: proc(position: [3]f32, size: [2]f32, top_radius: f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cone_Frustum)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {size.x, size.y / 2, size.x}
    instance.radius = top_radius
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_frustum_o :: proc(position: [3]f32, size: [2]f32, top_radius: f32, rotation: quaternion128, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Cone_Frustum)
    instance.translation = position
    instance.rotation = rotation
    instance.scale = {size.x, size.y / 2, size.x}
    instance.radius = top_radius
    instance.color = color
    instance.wire_color = wire_color
}

draw_cone_frustum_ab :: proc(start: [3]f32, end: [3]f32, bottom_radius: f32, top_radius: f32, color: u32, wire_color: u32 = 0) {
    height := glm.distance(start, end) / 2

    instance := triprim_push(.Cone_Frustum)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(end - start))
    instance.scale = {bottom_radius, height, bottom_radius}
    instance.radius = top_radius
    instance.color = color
    instance.wire_color = wire_color
}

draw_sphere :: proc(position: [3]f32, radius: f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Sphere)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {radius, radius, radius}
    instance.color = color
    instance.wire_color = wire_color
}

draw_capsule_aa :: proc(position: [3]f32, size: [2]f32, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Capsule)
    instance.translation = position
    instance.rotation = {}
    instance.scale = {0, size.y / 2, 0}
    instance.radius = size.x
    instance.color = color
    instance.wire_color = wire_color
}

draw_capsule_o :: proc(position: [3]f32, size: [2]f32, rotation: quaternion128, color: u32, wire_color: u32 = 0) {
    instance := triprim_push(.Capsule)
    instance.translation = position
    instance.rotation = rotation
    instance.scale = {0, size.y / 2, 0}
    instance.radius = size.x
    instance.color = color
    instance.wire_color = wire_color
}

draw_capsule_ab :: proc(start: [3]f32, end: [3]f32, radius: f32, color: u32, wire_color: u32 = 0) {
    half_height := glm.distance(start, end) / 2

    instance := triprim_push(.Capsule)
    instance.translation = (start + end) / 2
    instance.rotation = quat_rotation_dir(glm.normalize(end - start))
    instance.scale = {0, half_height, 0}
    instance.radius = radius
    instance.color = color
    instance.wire_color = wire_color
}

draw_arrow :: proc(point0: [3]f32, point1: [3]f32, width: f32, head_size: f32, color: u32, wire_color: u32 = 0) {
    diff := point1 - point0
    length := glm.length(diff)

    if length == 0 {
        return
    }

    dir := diff / length
    body_end := point1 - dir * head_size

    draw_cylinder_ab(point0, body_end, width * 0.5, color, wire_color)
    draw_cone_ab(point1, body_end, head_size * 0.5, color, wire_color)
}

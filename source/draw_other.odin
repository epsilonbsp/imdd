package imdd3

import glm "core:math/linalg/glsl"

// API
draw_frustum :: proc(proj_view: matrix[4, 4]f32, line_width: f32, color: u32) {
    inv_proj_view := glm.inverse(proj_view)

    corners: [8][3]f32

    ndc := [8][4]f32{
        {-1, -1, -1, 1},
        { 1, -1, -1, 1},
        { 1,  1, -1, 1},
        {-1,  1, -1, 1},
        {-1, -1,  1, 1},
        { 1, -1,  1, 1},
        { 1,  1,  1, 1},
        {-1,  1,  1, 1},
    }

    for i in 0 ..< 8 {
        p := inv_proj_view * ndc[i]
        p /= p.w
        corners[i] = p.xyz
    }

    draw_line(corners[0], corners[1], line_width, color)
    draw_line(corners[1], corners[2], line_width, color)
    draw_line(corners[2], corners[3], line_width, color)
    draw_line(corners[3], corners[0], line_width, color)

    // Far plane
    draw_line(corners[4], corners[5], line_width, color)
    draw_line(corners[5], corners[6], line_width, color)
    draw_line(corners[6], corners[7], line_width, color)
    draw_line(corners[7], corners[4], line_width, color)

    // Sides
    draw_line(corners[0], corners[4], line_width, color)
    draw_line(corners[1], corners[5], line_width, color)
    draw_line(corners[2], corners[6], line_width, color)
    draw_line(corners[3], corners[7], line_width, color)
}

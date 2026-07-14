package imdd3

import glm "core:math/linalg/glsl"

// API
draw_line_cross :: proc(center: [3]f32, size: f32, line_width: f32, color: u32) {
    half := size * 0.5

    draw_line(center - {half, 0, 0}, center + {half, 0, 0}, line_width, color)
    draw_line(center - {0, half, 0}, center + {0, half, 0}, line_width, color)
    draw_line(center - {0, 0, half}, center + {0, 0, half}, line_width, color)
}

draw_gizmo :: proc(position: [3]f32, size: f32, width: f32) {
    head_size := width * 3

    draw_arrow(position, position + {size, 0, 0}, width, head_size, 0xff0000ff)
    draw_arrow(position, position + {0, size, 0}, width, head_size, 0x00ff00ff)
    draw_arrow(position, position + {0, 0, size}, width, head_size, 0x0000ffff)
}

draw_line_gizmo :: proc(position: [3]f32, size: f32, line_width: f32) {
    head_size := line_width * 3

    draw_line_arrow(position, position + {size, 0, 0}, line_width, head_size, 0xff0000ff)
    draw_line_arrow(position, position + {0, size, 0}, line_width, head_size, 0x00ff00ff)
    draw_line_arrow(position, position + {0, 0, size}, line_width, head_size, 0x0000ffff)
}

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

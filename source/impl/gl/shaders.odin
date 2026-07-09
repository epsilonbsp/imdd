package imdd33_impl_gl

GLSL_VERSION :: "#version 460 core"

MAIN_VS :: GLSL_VERSION + `
    layout(location = 0) in uint i_mode;
    layout(location = 1) in vec3 i_position;
    layout(location = 2) in vec2 i_tex_coord;
    layout(location = 3) in uint i_tex_index;
    layout(location = 4) in uvec2 i_colors;
    layout(location = 5) in vec4 i_params;

    flat out uint v_mode;
    out vec2 v_tex_coord;
    flat out uint v_tex_index;
    out vec4 v_color0;
    out vec4 v_color1;
    out vec4 v_params;
    out vec2 v_sdf_coord;

    uniform mat4 u_projection;

    const vec2 SDF_COORDS[] = vec2[](
        vec2(-1.0, -1.0),
        vec2(1.0, -1.0),
        vec2(1.0, 1.0),
        vec2(-1.0, 1.0)
    );

    vec4 unpack_color(uint color) {
        return vec4(
            (color >> 24) & 0xFF,
            (color >> 16) & 0xFF,
            (color >> 8) & 0xFF,
            color & 0xFF
        ) / 255.0;
    }

    void main() {
        gl_Position = u_projection * vec4(i_position, 1.0);

        v_mode = i_mode;
        v_tex_coord = i_tex_coord;
        v_tex_index = i_tex_index;
        v_color0 = unpack_color(i_colors.x);
        v_color1 = unpack_color(i_colors.y);
        v_params = i_params;

        if (i_mode >= 1 && i_mode <= 4) {
            v_sdf_coord = SDF_COORDS[i_mode - 1];
        }
    }
`

MAIN_FS :: GLSL_VERSION + `
    #extension GL_ARB_bindless_texture : require

    flat in uint v_mode;
    in vec2 v_tex_coord;
    flat in uint v_tex_index;
    in vec4 v_color0;
    in vec4 v_color1;
    in vec4 v_params;
    in vec2 v_sdf_coord;

    out vec4 o_frag_color;

    uniform sampler2D u_atlas_tex;

    layout(std430, binding = 0) readonly buffer TextureHandles {
        sampler2D tex_handle_arr[];
    };

    float median(float r, float g, float b) {
        return max(min(r, g), min(max(r, g), b));
    }

    float grid(vec2 uv, vec2 line_width) {
        vec2 ddx = dFdx(uv), ddy = dFdy(uv);
        vec2 uv_deriv = vec2(length(vec2(ddx.x, ddy.x)), length(vec2(ddx.y, ddy.y)));
        vec2 line_aa = uv_deriv * 1.5;

        bvec2 invert_line = bvec2(line_width.x > 0.5, line_width.y > 0.5);
        vec2 target_width = vec2(
            invert_line.x ? 1.0 - line_width.x : line_width.x,
            invert_line.y ? 1.0 - line_width.y : line_width.y
        );
        vec2 draw_width = clamp(target_width, uv_deriv, vec2(0.5));

        vec2 grid_uv = abs(fract(uv) * 2.0 - 1.0);
        grid_uv.x = invert_line.x ? grid_uv.x : 1.0 - grid_uv.x;
        grid_uv.y = invert_line.y ? grid_uv.y : 1.0 - grid_uv.y;

        vec2 alpha = smoothstep(draw_width + line_aa, draw_width - line_aa, grid_uv);
        alpha *= clamp(target_width / draw_width, 0.0, 1.0);
        alpha = mix(alpha, target_width, clamp(uv_deriv * 2.0 - 1.0, 0.0, 1.0));
        alpha.x = invert_line.x ? 1.0 - alpha.x : alpha.x;
        alpha.y = invert_line.y ? 1.0 - alpha.y : alpha.y;

        return mix(alpha.x, 1.0, alpha.y);
    }

    void main() {
        if (v_mode == 0) {
            o_frag_color = texture(tex_handle_arr[v_tex_index], v_tex_coord) * v_color0;
        } else if (v_mode >= 1 && v_mode <= 4) {
            vec2 extent = v_params.xy;
            float radius = v_params.z;
            float outline = v_params.w;

            vec2 q = abs(v_sdf_coord * extent) - extent + radius;
            float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
            float aa = fwidth(d) * 0.5;

            float fill_a = smoothstep(aa, -aa, d + outline);
            float stroke_a = smoothstep(-aa, aa, d + outline) * smoothstep(aa, -aa, d);

            o_frag_color = mix(
                texture(tex_handle_arr[v_tex_index], v_tex_coord) * vec4(v_color0.rgb, v_color0.a * fill_a),
                vec4(v_color1.rgb, v_color1.a * stroke_a),
                stroke_a
            );
        } else if (v_mode == 5) {
            float px_range = v_params.x;

            vec4 msd = texture(u_atlas_tex, v_tex_coord);
            float sd = mix(median(msd.r, msd.g, msd.b), msd.a, clamp(px_range - 1.0, 0.0, 1.0));
            float screen_px_dist = px_range * (sd - 0.5);
            float opacity = clamp(screen_px_dist + 0.5, 0.0, 1.0);

            o_frag_color = vec4(v_color0.rgb, v_color0.a * opacity);
        } else if (v_mode == 6) {
            vec2 cell_size = v_params.xy;
            float line_width = v_params.z;

            vec2 uv = v_tex_coord / cell_size;
            float alpha = grid(uv, vec2(line_width / cell_size.x, line_width / cell_size.y));

            o_frag_color = vec4(v_color0.rgb, v_color0.a * alpha);
        }
    }
`

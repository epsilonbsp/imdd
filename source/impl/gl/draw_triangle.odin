package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

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
    uniform mat4 u_view;

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
        gl_Position = u_projection * u_view * vec4(i_position, 1.0);

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
            float distance = v_params.x;
            float dash_length = v_params.y;

            if (dash_length > 0.0 && mod(distance, dash_length * 2.0) > dash_length) {
                discard;
            }

            o_frag_color = v_color0;
        } else if (v_mode == 6) {
            vec2 cell_size = v_params.xy;
            float line_width = v_params.z;

            vec2 uv = v_tex_coord / cell_size;
            float alpha = grid(uv, vec2(line_width / cell_size.x, line_width / cell_size.y));

            o_frag_color = vec4(v_color0.rgb, v_color0.a * alpha);
        } else if (v_mode == 7) {
            vec2 unit_range = vec2(v_params.x) / vec2(textureSize(u_atlas_tex, 0));
            vec2 screen_tex_size = vec2(1.0) / fwidth(v_tex_coord);
            float px_range = max(0.5 * dot(unit_range, screen_tex_size), 1.0);

            vec4 msd = texture(u_atlas_tex, v_tex_coord);
            float sd = mix(median(msd.r, msd.g, msd.b), msd.a, clamp(px_range - 1.0, 0.0, 1.0));
            float screen_px_dist = px_range * (sd - 0.5);
            float opacity = clamp(screen_px_dist + 0.5, 0.0, 1.0);

            o_frag_color = vec4(v_color0.rgb, v_color0.a * opacity);
        }
    }
`

Triangle_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    vbo: u32,
    ibo: u32,
}

triangle_state: Triangle_State

triangle_init :: proc() {
    ok: bool
    triangle_state.program, ok = load_shaders({{.VERTEX_SHADER, MAIN_VS}, {.FRAGMENT_SHADER, MAIN_FS}})
    triangle_state.uniforms = gl.get_uniforms_from_program(triangle_state.program)
    assert(ok, "ERROR: Failed to compile triangle program")

    gl.GenVertexArrays(1, &triangle_state.vao)
    gl.BindVertexArray(triangle_state.vao)

    gl.GenBuffers(1, &triangle_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triangle_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.TRIANGLE_VERTEX_CAP * size_of(imdd3.Triangle_Vertex), nil, gl.STREAM_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribIPointer(0, 1, gl.UNSIGNED_INT, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, mode))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, position))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, tex_coord))

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.UNSIGNED_INT, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, tex_index))

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 2, gl.UNSIGNED_INT, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, colors))

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribPointer(5, 4, gl.FLOAT, gl.FALSE, size_of(imdd3.Triangle_Vertex), offset_of(imdd3.Triangle_Vertex, params))

    gl.GenBuffers(1, &triangle_state.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, triangle_state.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, imdd3.TRIANGLE_INDEX_CAP * size_of(u32), nil, gl.STREAM_DRAW)
}

triangle_destroy :: proc() {
    gl.DeleteProgram(triangle_state.program)
    gl.destroy_uniforms(triangle_state.uniforms)

    gl.DeleteVertexArrays(1, &triangle_state.vao)
    gl.DeleteBuffers(1, &triangle_state.vbo)
    gl.DeleteBuffers(1, &triangle_state.ibo)
}

triangle_render :: proc(vertices: []imdd3.Triangle_Vertex, indices: []u32) {
    if len(vertices) == 0 {
        return
    }

    gl.UseProgram(triangle_state.program)
    gl.UniformMatrix4fv(triangle_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(triangle_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(triangle_state.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, triangle_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.TRIANGLE_VERTEX_CAP * size_of(imdd3.Triangle_Vertex), nil, gl.STREAM_DRAW)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * size_of(imdd3.Triangle_Vertex), raw_data(vertices))

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, triangle_state.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, imdd3.TRIANGLE_INDEX_CAP * size_of(u32), nil, gl.STREAM_DRAW)
    gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, len(indices) * size_of(u32), raw_data(indices))

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, renderer.atlas_tex)
    gl.Uniform1i(triangle_state.uniforms["u_atlas_tex"].location, 0)

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, renderer.tex_map.ssbo)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)
}

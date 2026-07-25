package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

LINE_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_position;
    layout(location = 1) in float i_radius;
    layout(location = 2) in uint i_color;
    layout(location = 3) in float i_distance;
    layout(location = 4) in float i_dash;
    layout(location = 5) in uint i_is_rounded;

    out Vertex_Data {
        float radius;
        uint color;
        float distance;
        float dash;
        uint is_rounded;
    } v_data;

    void main() {
        gl_Position = vec4(i_position, 1.0);
        v_data.radius = i_radius;
        v_data.color = i_color;
        v_data.distance = i_distance;
        v_data.dash = i_dash;
        v_data.is_rounded = i_is_rounded;
    }
`

LINE_GS :: GLSL_VERSION + `
    layout(lines) in;
    layout(triangle_strip, max_vertices = 4) out;

    in Vertex_Data {
        float radius;
        uint color;
        float distance;
        float dash;
        uint is_rounded;
    } v_data[];

    out vec4 v_color;
    out float v_distance;
    flat out float v_dash;
    flat out uint v_is_rounded;
    out vec2 v_tex_coord;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec4 unpack_rgba(uint i) {
        return vec4(
            float((i >> 24) & 0xFFu),
            float((i >> 16) & 0xFFu),
            float((i >> 8) & 0xFFu),
            float(i & 0xFFu)
        ) / 255.0;
    }

    void main() {
        vec4 view0 = u_view * gl_in[0].gl_Position;
        vec4 view1 = u_view * gl_in[1].gl_Position;

        vec3 line_dir = normalize(view1.xyz - view0.xyz);
        vec3 to_cam = normalize(-(view0.xyz + view1.xyz) * 0.5);
        vec3 view_perp = normalize(cross(line_dir, to_cam));

        vec4 color0 = unpack_rgba(v_data[0].color);
        vec4 color1 = unpack_rgba(v_data[1].color);

        v_dash = v_data[0].dash;

        gl_Position = u_projection * vec4(view0.xyz - view_perp * v_data[0].radius, 1.0);
        v_color = color0;
        v_distance = v_data[0].distance;
        v_is_rounded = v_data[0].is_rounded;
        v_tex_coord = vec2(-1.0, 0.0);
        EmitVertex();

        gl_Position = u_projection * vec4(view0.xyz + view_perp * v_data[0].radius, 1.0);
        v_color = color0;
        v_distance = v_data[0].distance;
        v_is_rounded = v_data[0].is_rounded;
        v_tex_coord = vec2(1.0, 0.0);
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz - view_perp * v_data[1].radius, 1.0);
        v_color = color1;
        v_distance = v_data[1].distance;
        v_is_rounded = v_data[1].is_rounded;
        v_tex_coord = vec2(-1.0, 1.0);
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz + view_perp * v_data[1].radius, 1.0);
        v_color = color1;
        v_distance = v_data[1].distance;
        v_is_rounded = v_data[1].is_rounded;
        v_tex_coord = vec2(1.0, 1.0);
        EmitVertex();

        EndPrimitive();
    }
`

LINE_FS :: GLSL_VERSION + `
    in vec4 v_color;
    in float v_distance;
    flat in float v_dash;
    flat in uint v_is_rounded;
    in vec2 v_tex_coord;

    out vec4 o_frag_color;

    void main() {
        if (v_dash > 0.0 && mod(v_distance, v_dash * 2.0) > v_dash) {
            discard;
        }

        if (v_is_rounded == 1u) {
            vec2 cp = v_tex_coord;

            if (cp.x * cp.x + cp.y * cp.y > 1.0) {
                discard;
            }
        }

        o_frag_color = v_color;
    }
`

Line_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    vbo: u32,
}

line_state: Line_State

line_init :: proc() {
    ok: bool
    line_state.program, ok = load_shaders({
        {.VERTEX_SHADER, LINE_VS},
        {.GEOMETRY_SHADER, LINE_GS},
        {.FRAGMENT_SHADER, LINE_FS},
    })
    assert(ok, "ERROR: Failed to compile line program")
    line_state.uniforms = gl.get_uniforms_from_program(line_state.program)

    gl.GenVertexArrays(1, &line_state.vao)
    gl.BindVertexArray(line_state.vao)

    gl.GenBuffers(1, &line_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, line_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.LINE_VERTEX_CAP * size_of(imdd3.Line_Vertex), nil, gl.DYNAMIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, position))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 1, gl.FLOAT, false, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, radius))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribIPointer(2, 1, gl.UNSIGNED_INT, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, color))

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 1, gl.FLOAT, false, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, distance))

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 1, gl.FLOAT, false, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, dash))

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 1, gl.UNSIGNED_INT, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, is_rounded))
}

line_destroy :: proc() {
    gl.DeleteProgram(line_state.program)
    gl.destroy_uniforms(line_state.uniforms)

    gl.DeleteVertexArrays(1, &line_state.vao)
    gl.DeleteBuffers(1, &line_state.vbo)
}

line_render :: proc(vertices: []imdd3.Line_Vertex) {
    if len(vertices) < 2 {
        return
    }

    gl.UseProgram(line_state.program)
    gl.UniformMatrix4fv(line_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(line_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(line_state.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, line_state.vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * size_of(imdd3.Line_Vertex), raw_data(vertices))

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DrawArrays(gl.LINES, 0, i32(len(vertices)))
}

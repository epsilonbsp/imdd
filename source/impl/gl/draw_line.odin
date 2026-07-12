package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

LINE_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_position;
    layout(location = 1) in float i_radius;
    layout(location = 2) in uint i_color;
    layout(location = 3) in uint i_rounded;

    out Vertex_Data {
        float radius;
        uint color;
        uint rounded;
    } v_data;

    void main() {
        gl_Position = vec4(i_position, 1.0);
        v_data.radius = i_radius;
        v_data.color = i_color;
        v_data.rounded = i_rounded;
    }
`

LINE_GS :: GLSL_VERSION + `
    layout(lines) in;
    layout(triangle_strip, max_vertices = 4) out;

    in Vertex_Data {
        float radius;
        uint color;
        uint rounded;
    } v_data[];

    out vec4 v_color;
    out vec2 v_tex_coord;
    flat out uint v_round;

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

        vec4 clip0 = u_projection * view0;
        vec4 clip1 = u_projection * view1;

        vec2 screen0 = clip0.xy / clip0.w;
        vec2 screen1 = clip1.xy / clip1.w;

        vec2 screen_dir = normalize(screen1 - screen0);
        vec3 view_perp = normalize(vec3(-screen_dir.y, screen_dir.x, 0.0));

        vec4 color0 = unpack_rgba(v_data[0].color);
        vec4 color1 = unpack_rgba(v_data[1].color);

        gl_Position = u_projection * vec4(view0.xyz - view_perp * v_data[0].radius, 1.0);
        v_color = color0; v_tex_coord = vec2(-1.0, 0.0); v_round = v_data[0].rounded;
        EmitVertex();

        gl_Position = u_projection * vec4(view0.xyz + view_perp * v_data[0].radius, 1.0);
        v_color = color0; v_tex_coord = vec2(1.0, 0.0); v_round = v_data[0].rounded;
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz - view_perp * v_data[1].radius, 1.0);
        v_color = color1; v_tex_coord = vec2(-1.0, 1.0); v_round = v_data[1].rounded;
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz + view_perp * v_data[1].radius, 1.0);
        v_color = color1; v_tex_coord = vec2(1.0, 1.0); v_round = v_data[1].rounded;
        EmitVertex();

        EndPrimitive();
    }
`

LINE_FS :: GLSL_VERSION + `
    in vec4 v_color;
    in vec2 v_tex_coord;
    flat in uint v_round;

    out vec4 o_frag_color;

    void main() {
        if (v_round == 1u) {
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
    gl.VertexAttribIPointer(3, 1, gl.UNSIGNED_INT, size_of(imdd3.Line_Vertex), offset_of(imdd3.Line_Vertex, is_rounded))
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
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DrawArrays(gl.LINES, 0, i32(len(vertices)))
}

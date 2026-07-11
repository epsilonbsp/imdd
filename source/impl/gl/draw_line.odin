package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

LINE_VS :: GLSL_VERSION + `
    struct Line_Vertex {
        vec3 position;
        float radius;
        uint is_connected;
        uint color;
    };

    layout(std430, binding = 0) readonly buffer Line_Vertices {
        Line_Vertex vertices[];
    };

    out vec4 v_color;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    const vec2 offsets[4] = vec2[](
        vec2(-0.5, 0.0),
        vec2( 0.5, 0.0),
        vec2(-0.5, 1.0),
        vec2( 0.5, 1.0)
    );

    vec4 unpack_rgba(uint i) {
        return vec4(
            float((i >> 24) & 0xFFu),
            float((i >> 16) & 0xFFu),
            float((i >> 8) & 0xFFu),
            float(i & 0xFFu)
        ) / 255.0;
    }

    void main() {
        Line_Vertex curr = vertices[gl_InstanceID];

        if (curr.is_connected == 0u) {
            gl_Position = vec4(0.0, 0.0, 0.0, 0.0);

            return;
        }

        Line_Vertex next = vertices[gl_InstanceID + 1];

        vec4 view_curr = u_view * vec4(curr.position, 1.0);
        vec4 view_next = u_view * vec4(next.position, 1.0);

        vec4 clip_curr = u_projection * view_curr;
        vec4 clip_next = u_projection * view_next;

        vec2 screen_curr = clip_curr.xy / clip_curr.w;
        vec2 screen_next = clip_next.xy / clip_next.w;

        vec2 screen_dir = normalize(screen_next - screen_curr);
        vec3 view_perp = normalize(vec3(-screen_dir.y, screen_dir.x, 0.0));

        float dx = offsets[gl_VertexID].x;
        float dy = offsets[gl_VertexID].y;

        vec3 view_pos = mix(view_curr.xyz, view_next.xyz, dy) + view_perp * mix(curr.radius, next.radius, dy) * dx;

        gl_Position = u_projection * vec4(view_pos, 1.0);
        v_color = unpack_rgba(dy < 0.5 ? curr.color : next.color);
    }
`

LINE_FS :: GLSL_VERSION + `
    precision highp float;

    in vec4 v_color;

    out vec4 o_frag_color;

    void main() {
        o_frag_color = v_color;
    }
`

Line_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    ssbo: u32,
}

line_state: Line_State

line_init :: proc() {
    ok: bool
    line_state.program, ok = gl.load_shaders_source(LINE_VS, LINE_FS)
    line_state.uniforms = gl.get_uniforms_from_program(line_state.program)
    assert(ok, "ERROR: Failed to compile line program")

    gl.GenVertexArrays(1, &line_state.vao)

    gl.GenBuffers(1, &line_state.ssbo)
    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, line_state.ssbo)
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(imdd3.Line_Vertex) * imdd3.LINE_VERTEX_CAP, nil, gl.DYNAMIC_DRAW)
}

line_destroy :: proc() {
    gl.DeleteProgram(line_state.program)
    gl.destroy_uniforms(line_state.uniforms)
    gl.DeleteVertexArrays(1, &line_state.vao)
    gl.DeleteBuffers(1, &line_state.ssbo)
}

line_render :: proc(vertices: []imdd3.Line_Vertex, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    if len(vertices) < 2 {
        return
    }

    projection := projection
    view := view

    gl.UseProgram(line_state.program)
    gl.UniformMatrix4fv(line_state.uniforms["u_projection"].location, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(line_state.uniforms["u_view"].location, 1, false, &view[0][0])

    gl.BindVertexArray(line_state.vao)

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, line_state.ssbo)
    gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, 0, len(vertices) * size_of(imdd3.Line_Vertex), raw_data(vertices))
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, line_state.ssbo)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, i32(len(vertices) - 1))
}

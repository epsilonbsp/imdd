package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

LINEPRIM_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_translation;
    layout(location = 1) in vec4 i_rotation;
    layout(location = 2) in vec3 i_scale;
    layout(location = 3) in float i_radius;
    layout(location = 4) in uint i_color;
    layout(location = 5) in uvec2 i_range;

    struct Vertex {
        vec4 anchor;
        vec4 direction;
    };

    layout(std430, binding = 0) readonly buffer VertexBuffer {
        Vertex vertex_data[];
    };

    layout(std430, binding = 1) readonly buffer IndexBuffer {
        uint index_data[];
    };

    out Geometry_Data {
        vec4 color;
    } v_gd;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 rotate(vec3 v, vec4 q) {
        return 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v) + v;
    }

    vec4 unpack_rgba(uint i) {
        return vec4(
            (i >> 24) & 0xFF,
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        if (uint(gl_VertexID) >= i_range.y) {
            gl_Position = vec4(0.0);
            v_gd.color = vec4(0.0);

            return;
        }

        uint vertex_index = index_data[i_range.x + uint(gl_VertexID)];
        Vertex v = vertex_data[vertex_index];

        vec3 local_pos = v.anchor.xyz * i_scale + v.direction.xyz * i_radius;
        gl_Position = vec4(rotate(local_pos, i_rotation) + i_translation, 1.0);
        v_gd.color = unpack_rgba(i_color);
    }
`

LINEPRIM_GS :: GLSL_VERSION + `
    #define LINE_WIDTH 2.0

    layout (lines) in;
    layout (triangle_strip, max_vertices = 4) out;

    out vec4 v_color;
    out float v_width;
    out float v_dist;
    out float v_depth;

    in Geometry_Data {
        vec4 color;
    } v_gd[];

    uniform mat4 u_projection;
    uniform mat4 u_view;
    uniform vec2 u_viewport;

    void main() {
        vec4 p0_world = gl_in[0].gl_Position;
        vec4 p1_world = gl_in[1].gl_Position;

        vec4 p0_view = u_view * p0_world;
        vec4 p1_view = u_view * p1_world;

        vec4 p0_clip = u_projection * p0_view;
        vec4 p1_clip = u_projection * p1_view;

        if (p0_clip.w == 0.0 || p1_clip.w == 0.0) {
            return;
        }

        vec2 p0_ndc = p0_clip.xy / p0_clip.w;
        vec2 p1_ndc = p1_clip.xy / p1_clip.w;

        vec2 p0_screen = p0_ndc * u_viewport * 0.5;
        vec2 p1_screen = p1_ndc * u_viewport * 0.5;

        vec2 dir = normalize(p1_screen - p0_screen);
        vec2 normal = vec2(-dir.y, dir.x);
        vec2 offset = normal * (LINE_WIDTH * 0.5);

        vec2 p0a_screen = p0_screen + offset;
        vec2 p0b_screen = p0_screen - offset;
        vec2 p1a_screen = p1_screen + offset;
        vec2 p1b_screen = p1_screen - offset;

        vec2 p0a_ndc = p0a_screen / (u_viewport * 0.5);
        vec2 p0b_ndc = p0b_screen / (u_viewport * 0.5);
        vec2 p1a_ndc = p1a_screen / (u_viewport * 0.5);
        vec2 p1b_ndc = p1b_screen / (u_viewport * 0.5);

        v_color = v_gd[0].color;
        v_width = LINE_WIDTH;

        v_dist = 0.5;
        v_depth = -p0_view.z;
        gl_Position = vec4(p0a_ndc * p0_clip.w, p0_clip.z, p0_clip.w);
        EmitVertex();

        v_dist = -0.5;
        v_depth = -p0_view.z;
        gl_Position = vec4(p0b_ndc * p0_clip.w, p0_clip.z, p0_clip.w);
        EmitVertex();

        v_dist = 0.5;
        v_depth = -p1_view.z;
        gl_Position = vec4(p1a_ndc * p1_clip.w, p1_clip.z, p1_clip.w);
        EmitVertex();

        v_dist = -0.5;
        v_depth = -p1_view.z;
        gl_Position = vec4(p1b_ndc * p1_clip.w, p1_clip.z, p1_clip.w);
        EmitVertex();
    }
`

LINEPRIM_FS :: GLSL_VERSION + `
    #define AA_WIDTH 1.0

    in vec4 v_color;
    in float v_width;
    in float v_dist;
    in float v_depth;

    out vec4 o_frag_color;

    void main() {
        float dist = abs(v_dist) * v_width;
        float alpha = 1.0 - smoothstep(v_width * 0.5 - AA_WIDTH, v_width * 0.5, dist);

        if (alpha <= 0.0) {
            discard;
        }

        o_frag_color = vec4(v_color.rgb, alpha);
    }
`

Lineprim_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    ibo: u32,
    vertex_ssbo: u32,
    index_ssbo: u32,
}

lineprim_state: Lineprim_State

lineprim_init :: proc(vertices: []imdd3.Lineprim_Vertex, indices: []u32, ranges: [imdd3.Lineprim_Type]imdd3.Lineprim_Range) {
    Lineprim_Vertex :: struct {
        anchor: [4]f32,
        direction: [4]f32,
    }

    ok: bool
    lineprim_state.program, ok = load_shaders({
        {.VERTEX_SHADER, LINEPRIM_VS},
        {.GEOMETRY_SHADER, LINEPRIM_GS},
        {.FRAGMENT_SHADER, LINEPRIM_FS},
    })
    assert(ok, "ERROR: Failed to compile lineprim program")
    lineprim_state.uniforms = gl.get_uniforms_from_program(lineprim_state.program)

    vertices_gl := make([]Lineprim_Vertex, len(vertices)); defer delete(vertices_gl)

    for vertex, i in vertices {
        vertices_gl[i] = {
            anchor = {vertex.anchor.x, vertex.anchor.y, vertex.anchor.z, 0},
            direction = {vertex.direction.x, vertex.direction.y, vertex.direction.z, 0},
        }
    }

    gl.GenBuffers(1, &lineprim_state.vertex_ssbo)
    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, lineprim_state.vertex_ssbo)
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(Lineprim_Vertex) * len(vertices_gl), raw_data(vertices_gl), gl.STATIC_DRAW)

    gl.GenBuffers(1, &lineprim_state.index_ssbo)
    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, lineprim_state.index_ssbo)
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.STATIC_DRAW)

    gl.GenVertexArrays(1, &lineprim_state.vao)
    gl.BindVertexArray(lineprim_state.vao)

    gl.GenBuffers(1, &lineprim_state.ibo)
    gl.BindBuffer(gl.ARRAY_BUFFER, lineprim_state.ibo)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, translation))
    gl.VertexAttribDivisor(0, 1)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, rotation))
    gl.VertexAttribDivisor(1, 1)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, scale))
    gl.VertexAttribDivisor(2, 1)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 1, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, radius))
    gl.VertexAttribDivisor(3, 1)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.UNSIGNED_INT, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, color))
    gl.VertexAttribDivisor(4, 1)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 2, gl.UNSIGNED_INT, size_of(imdd3.Lineprim_Instance), offset_of(imdd3.Lineprim_Instance, range))
    gl.VertexAttribDivisor(5, 1)
}

lineprim_destroy :: proc() {
    gl.DeleteProgram(lineprim_state.program)
    gl.destroy_uniforms(lineprim_state.uniforms)

    gl.DeleteVertexArrays(1, &lineprim_state.vao)
    gl.DeleteBuffers(1, &lineprim_state.ibo)
    gl.DeleteBuffers(1, &lineprim_state.vertex_ssbo)
    gl.DeleteBuffers(1, &lineprim_state.index_ssbo)
}

lineprim_render :: proc(data: []imdd3.Lineprim_Instance, max_index_count: u32) {
    if len(data) == 0 {
        return
    }

    gl.UseProgram(lineprim_state.program)
    gl.Uniform2f(lineprim_state.uniforms["u_viewport"].location, f32(renderer.viewport[0]), f32(renderer.viewport[1]))
    gl.UniformMatrix4fv(lineprim_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(lineprim_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(lineprim_state.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, lineprim_state.ibo)
    gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(imdd3.Lineprim_Instance), raw_data(data), gl.STREAM_DRAW)
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, lineprim_state.vertex_ssbo)
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, lineprim_state.index_ssbo)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DrawArraysInstanced(gl.LINES, 0, i32(max_index_count), i32(len(data)))
}

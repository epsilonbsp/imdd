package imdd3_impl_gl

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

import imdd3 "../.."

LINEPRIM_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec3 i_translation;
    layout(location = 2) in vec4 i_rotation;
    layout(location = 3) in vec3 i_scale;
    layout(location = 4) in uint i_color;

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
        gl_Position = vec4(rotate(i_position * i_scale, i_rotation) + i_translation, 1.0);
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

    uniform vec2 u_viewport;
    uniform sampler2D sa_depth;

    void main() {
        #ifdef USE_DEPTH
            vec2 rm_uv = vec2(gl_FragCoord.x, u_viewport.y - gl_FragCoord.y) / u_viewport;
            float rm_depth = texture(sa_depth, rm_uv).x;

            if (rm_depth < v_depth) {
                discard;
            }
        #endif

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
    vbo: u32,
    ibo: u32,
    ubo: u32,
    dibo: u32,

    ranges: [imdd3.Lineprim_Type]imdd3.Lineprim_Range,
}

lineprim_state: Lineprim_State

lineprim_init :: proc(vertices: []glm.vec3, indices: []u32, ranges: [imdd3.Lineprim_Type]imdd3.Lineprim_Range) {
    lineprim_state.ranges = ranges

    ok: bool
    lineprim_state.program, ok = load_shaders({
        {.VERTEX_SHADER, LINEPRIM_VS},
        {.GEOMETRY_SHADER, LINEPRIM_GS},
        {.FRAGMENT_SHADER, LINEPRIM_FS},
    })
    assert(ok, "ERROR: Failed to compile lineprim program")
    lineprim_state.uniforms = gl.get_uniforms_from_program(lineprim_state.program)

    gl.GenVertexArrays(1, &lineprim_state.vao)
    gl.BindVertexArray(lineprim_state.vao)

    gl.GenBuffers(1, &lineprim_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, lineprim_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(glm.vec3) * len(vertices), raw_data(vertices), gl.DYNAMIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

    gl.GenBuffers(1, &lineprim_state.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, lineprim_state.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.DYNAMIC_DRAW)

    gl.GenBuffers(1, &lineprim_state.ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, lineprim_state.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Lineprim_Instance) * imdd3.LINEPRIM_CAP * len(imdd3.Lineprim_Type), nil, gl.DYNAMIC_DRAW)

    attrib_offset: uintptr = 0

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(1, 1)
    attrib_offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(2, 1)
    attrib_offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 3, gl.FLOAT, false, size_of(imdd3.Lineprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(3, 1)
    attrib_offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.UNSIGNED_INT, size_of(imdd3.Lineprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(4, 1)

    gl.GenBuffers(1, &lineprim_state.dibo)
}

lineprim_destroy :: proc() {
    gl.DeleteProgram(lineprim_state.program)
    gl.destroy_uniforms(lineprim_state.uniforms)

    gl.DeleteVertexArrays(1, &lineprim_state.vao)
    gl.DeleteBuffers(1, &lineprim_state.vbo)
    gl.DeleteBuffers(1, &lineprim_state.ibo)
    gl.DeleteBuffers(1, &lineprim_state.ubo)
    gl.DeleteBuffers(1, &lineprim_state.dibo)
}

lineprim_render :: proc(data: [imdd3.Lineprim_Type][]imdd3.Lineprim_Instance) {
    total := 0

    for type in imdd3.Lineprim_Type {
        total += len(data[type])
    }

    if total == 0 {
        return
    }

    gl.UseProgram(lineprim_state.program)
    gl.Uniform2f(lineprim_state.uniforms["u_viewport"].location, f32(renderer.viewport[0]), f32(renderer.viewport[1]))
    gl.UniformMatrix4fv(lineprim_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(lineprim_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(lineprim_state.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, lineprim_state.ubo)

    region_size :: size_of(imdd3.Lineprim_Instance) * imdd3.LINEPRIM_CAP

    commands: [len(imdd3.Lineprim_Type)]gl.DrawElementsIndirectCommand

    for type in imdd3.Lineprim_Type {
        i := int(type)
        instances := data[type]

        if len(instances) > 0 {
            gl.BufferSubData(gl.ARRAY_BUFFER, i * region_size, len(instances) * size_of(imdd3.Lineprim_Instance), raw_data(instances))
        }

        commands[i] = {
            count = u32(lineprim_state.ranges[type].count),
            instanceCount = u32(len(instances)),
            firstIndex = lineprim_state.ranges[type].first,
            baseVertex = 0,
            baseInstance = u32(i) * imdd3.LINEPRIM_CAP,
        }
    }

    gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, lineprim_state.dibo)
    gl.BufferData(gl.DRAW_INDIRECT_BUFFER, size_of(commands), &commands[0], gl.STREAM_DRAW)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.MultiDrawElementsIndirect(gl.LINES, gl.UNSIGNED_INT, nil, i32(len(imdd3.Lineprim_Type)), 0)
}

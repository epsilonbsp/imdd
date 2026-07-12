package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

TRIPRIM_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_position;
    layout(location = 1) in vec3 i_normal;
    layout(location = 2) in vec3 i_translation;
    layout(location = 3) in vec4 i_rotation;
    layout(location = 4) in vec3 i_scale;
    layout(location = 5) in uint i_color;

    out vec4 v_color;

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
        vec3 world_position = rotate(i_position * i_scale, i_rotation) + i_translation;
        gl_Position = u_projection * u_view * vec4(world_position, 1.0);
        v_color = unpack_rgba(i_color);
    }
`

TRIPRIM_FS :: GLSL_VERSION + `
in vec4 v_color;

out vec4 o_frag_color;

void main() {
    o_frag_color = v_color;
}
`

Triprim_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,

    vao: u32,
    vbo: u32,
    ibo: u32,
    ubo: u32,
    dibo: u32,

    ranges: [imdd3.Triprim_Type]imdd3.Triprim_Range,
}

triprim_state: Triprim_State

triprim_init :: proc(vertices: []imdd3.Triprim_Vertex, indices: []u32, ranges: [imdd3.Triprim_Type]imdd3.Triprim_Range) {
    triprim_state.ranges = ranges

    ok: bool
    triprim_state.program, ok = load_shaders({{.VERTEX_SHADER, TRIPRIM_VS}, {.FRAGMENT_SHADER, TRIPRIM_FS}})
    assert(ok, "ERROR: Failed to compile triprim program")
    triprim_state.uniforms = gl.get_uniforms_from_program(triprim_state.program)

    gl.GenVertexArrays(1, &triprim_state.vao)
    gl.BindVertexArray(triprim_state.vao)

    gl.GenBuffers(1, &triprim_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Triprim_Vertex) * len(vertices), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, position))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, normal))

    gl.GenBuffers(1, &triprim_state.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, triprim_state.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.STATIC_DRAW)

    gl.GenBuffers(1, &triprim_state.ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Triprim_Instance) * imdd3.TRIPRIM_CAP * len(imdd3.Triprim_Type), nil, gl.DYNAMIC_DRAW)

    attrib_offset: uintptr = 0

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(2, 1)
    attrib_offset += size_of([3]f32)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 4, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(3, 1)
    attrib_offset += size_of([4]f32)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(4, 1)
    attrib_offset += size_of([3]f32)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 1, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), attrib_offset)
    gl.VertexAttribDivisor(5, 1)

    gl.GenBuffers(1, &triprim_state.dibo)
}

triprim_destroy :: proc() {
    gl.DeleteProgram(triprim_state.program)
    gl.destroy_uniforms(triprim_state.uniforms)

    gl.DeleteVertexArrays(1, &triprim_state.vao)
    gl.DeleteBuffers(1, &triprim_state.vbo)
    gl.DeleteBuffers(1, &triprim_state.ibo)
    gl.DeleteBuffers(1, &triprim_state.ubo)
    gl.DeleteBuffers(1, &triprim_state.dibo)
}

triprim_render :: proc(data: [imdd3.Triprim_Type][]imdd3.Triprim_Instance) {
    total := 0

    for type in imdd3.Triprim_Type {
        total += len(data[type])
    }

    if total == 0 {
        return
    }

    gl.UseProgram(triprim_state.program)
    gl.UniformMatrix4fv(triprim_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(triprim_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(triprim_state.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ubo)

    region_size :: size_of(imdd3.Triprim_Instance) * imdd3.TRIPRIM_CAP

    commands: [len(imdd3.Triprim_Type)]gl.DrawElementsIndirectCommand

    for type in imdd3.Triprim_Type {
        i := int(type)
        instances := data[type]

        if len(instances) > 0 {
            gl.BufferSubData(gl.ARRAY_BUFFER, i * region_size, len(instances) * size_of(imdd3.Triprim_Instance), raw_data(instances))
        }

        commands[i] = {
            count = u32(triprim_state.ranges[type].count),
            instanceCount = u32(len(instances)),
            firstIndex = triprim_state.ranges[type].first,
            baseVertex = 0,
            baseInstance = u32(i) * imdd3.TRIPRIM_CAP,
        }
    }

    gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, triprim_state.dibo)
    gl.BufferData(gl.DRAW_INDIRECT_BUFFER, size_of(commands), &commands[0], gl.STREAM_DRAW)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.MultiDrawElementsIndirect(gl.TRIANGLES, gl.UNSIGNED_INT, nil, i32(len(imdd3.Triprim_Type)), 0)
}

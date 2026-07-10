package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

PRIMITIVE_VS :: `#version 460 core

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

PRIMITIVE_FS :: `#version 460 core
precision highp float;

in vec4 v_color;

out vec4 o_frag_color;

void main() {
    o_frag_color = v_color;
}
`

Primitive_Renderer :: struct {
    program: u32,
    uniforms: gl.Uniforms,

    vao: u32,
    vbo: u32,
    ibo: u32,
    ubo: u32,
    dibo: u32,

    ranges: [imdd3.Primitive_Type]imdd3.Primitive_Range,
}

primitive_renderer: Primitive_Renderer

primitive_renderer_init :: proc(vertices: []imdd3.Primitive_Vertex, indices: []u32, offset: [imdd3.Primitive_Type]imdd3.Primitive_Range) {
    ok: bool
    primitive_renderer.program, ok = gl.load_shaders_source(PRIMITIVE_VS, PRIMITIVE_FS)
    assert(ok, "ERROR: Failed to compile primitive program")
    primitive_renderer.uniforms = gl.get_uniforms_from_program(primitive_renderer.program)

    primitive_renderer.ranges = offset

    // vao
    gl.GenVertexArrays(1, &primitive_renderer.vao)
    gl.BindVertexArray(primitive_renderer.vao)

    // vbo
    gl.GenBuffers(1, &primitive_renderer.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, primitive_renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Primitive_Vertex) * len(vertices), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Primitive_Vertex), offset_of(imdd3.Primitive_Vertex, position))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(imdd3.Primitive_Vertex), offset_of(imdd3.Primitive_Vertex, normal))

    // ibo
    gl.GenBuffers(1, &primitive_renderer.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, primitive_renderer.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.STATIC_DRAW)

    // ubo (one region per primitive type, indexed via baseInstance)
    gl.GenBuffers(1, &primitive_renderer.ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, primitive_renderer.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Primitive_Instance) * imdd3.PRIMITIVE_CAP * len(imdd3.Primitive_Type), nil, gl.DYNAMIC_DRAW)

    attrib_offset: uintptr = 0

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(imdd3.Primitive_Instance), attrib_offset)
    gl.VertexAttribDivisor(2, 1)
    attrib_offset += size_of([3]f32)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 4, gl.FLOAT, false, size_of(imdd3.Primitive_Instance), attrib_offset)
    gl.VertexAttribDivisor(3, 1)
    attrib_offset += size_of([4]f32)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 3, gl.FLOAT, false, size_of(imdd3.Primitive_Instance), attrib_offset)
    gl.VertexAttribDivisor(4, 1)
    attrib_offset += size_of([3]f32)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 1, gl.UNSIGNED_INT, size_of(imdd3.Primitive_Instance), attrib_offset)
    gl.VertexAttribDivisor(5, 1)

    // draw indirect buffer
    gl.GenBuffers(1, &primitive_renderer.dibo)
}

primitive_renderer_destroy :: proc() {
    gl.DeleteProgram(primitive_renderer.program)
    gl.destroy_uniforms(primitive_renderer.uniforms)

    gl.DeleteVertexArrays(1, &primitive_renderer.vao)
    gl.DeleteBuffers(1, &primitive_renderer.vbo)
    gl.DeleteBuffers(1, &primitive_renderer.ibo)
    gl.DeleteBuffers(1, &primitive_renderer.ubo)
    gl.DeleteBuffers(1, &primitive_renderer.dibo)
}

primitive_renderer_render :: proc(data: [imdd3.Primitive_Type][]imdd3.Primitive_Instance, viewport: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)

    total := 0

    for type in imdd3.Primitive_Type {
        total += len(data[type])
    }

    if total == 0 {
        return
    }

    projection := projection
    view := view

    gl.UseProgram(primitive_renderer.program)
    gl.UniformMatrix4fv(primitive_renderer.uniforms["u_projection"].location, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(primitive_renderer.uniforms["u_view"].location, 1, false, &view[0][0])

    gl.BindVertexArray(primitive_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, primitive_renderer.ubo)

    region_size :: size_of(imdd3.Primitive_Instance) * imdd3.PRIMITIVE_CAP

    commands: [len(imdd3.Primitive_Type)]gl.DrawElementsIndirectCommand

    for type in imdd3.Primitive_Type {
        i := int(type)
        instances := data[type]

        if len(instances) > 0 {
            gl.BufferSubData(gl.ARRAY_BUFFER, i * region_size, len(instances) * size_of(imdd3.Primitive_Instance), raw_data(instances))
        }

        commands[i] = {
            count = u32(primitive_renderer.ranges[type].count),
            instanceCount = u32(len(instances)),
            firstIndex = primitive_renderer.ranges[type].first,
            baseVertex = 0,
            baseInstance = u32(i) * imdd3.PRIMITIVE_CAP,
        }
    }

    gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, primitive_renderer.dibo)
    gl.BufferData(gl.DRAW_INDIRECT_BUFFER, size_of(commands), &commands[0], gl.STREAM_DRAW)

    gl.MultiDrawElementsIndirect(gl.TRIANGLES, gl.UNSIGNED_INT, nil, i32(len(imdd3.Primitive_Type)), 0)
}

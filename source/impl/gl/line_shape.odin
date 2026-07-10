package imdd3_impl_gl

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

import imdd3 "../.."

Shape_Renderer :: struct {
    program: u32,
    uniforms: gl.Uniforms,

    vao: u32,
    vbo: u32,
    ibo: u32,
    ubo: u32,
    dibo: u32,

    offset: [imdd3.Shape_Type]imdd3.Index_Offset,
}

shape_renderer: Shape_Renderer

compile_shape_program :: proc() -> (program: u32, ok: bool) {
    vs := gl.compile_shader_from_source(SHAPE_VS, .VERTEX_SHADER) or_return
    defer gl.DeleteShader(vs)

    gs := gl.compile_shader_from_source(SHAPE_GS, .GEOMETRY_SHADER) or_return
    defer gl.DeleteShader(gs)

    fs := gl.compile_shader_from_source(SHAPE_FS, .FRAGMENT_SHADER) or_return
    defer gl.DeleteShader(fs)

    return gl.create_and_link_program([]u32{vs, gs, fs})
}

shape_init :: proc(vertices: []glm.vec3, indices: []u32, offset: [imdd3.Shape_Type]imdd3.Index_Offset) {
    ok: bool
    shape_renderer.program, ok = compile_shape_program()
    assert(ok, "ERROR: Failed to compile shape program")
    shape_renderer.uniforms = gl.get_uniforms_from_program(shape_renderer.program)

    shape_renderer.offset = offset

    // vao
    gl.GenVertexArrays(1, &shape_renderer.vao)
    gl.BindVertexArray(shape_renderer.vao)

    // vbo
    gl.GenBuffers(1, &shape_renderer.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, shape_renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(glm.vec3) * len(vertices), raw_data(vertices), gl.DYNAMIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

    // ibo
    gl.GenBuffers(1, &shape_renderer.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, shape_renderer.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.DYNAMIC_DRAW)

    // ubo (one region per shape type, indexed via baseInstance)
    gl.GenBuffers(1, &shape_renderer.ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, shape_renderer.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Debug_Shape) * imdd3.DEBUG_SHAPE_CAP * len(imdd3.Shape_Type), nil, gl.DYNAMIC_DRAW)

    attrib_offset: uintptr = 0

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(imdd3.Debug_Shape), attrib_offset)
    gl.VertexAttribDivisor(1, 1)
    attrib_offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(imdd3.Debug_Shape), attrib_offset)
    gl.VertexAttribDivisor(2, 1)
    attrib_offset += size_of(glm.vec4)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 3, gl.FLOAT, false, size_of(imdd3.Debug_Shape), attrib_offset)
    gl.VertexAttribDivisor(3, 1)
    attrib_offset += size_of(glm.vec3)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.UNSIGNED_INT, size_of(imdd3.Debug_Shape), attrib_offset)
    gl.VertexAttribDivisor(4, 1)

    // draw indirect buffer
    gl.GenBuffers(1, &shape_renderer.dibo)
}

shape_destroy :: proc() {
    gl.DeleteProgram(shape_renderer.program)
    gl.destroy_uniforms(shape_renderer.uniforms)

    gl.DeleteVertexArrays(1, &shape_renderer.vao)
    gl.DeleteBuffers(1, &shape_renderer.vbo)
    gl.DeleteBuffers(1, &shape_renderer.ibo)
    gl.DeleteBuffers(1, &shape_renderer.ubo)
    gl.DeleteBuffers(1, &shape_renderer.dibo)
}

shape_render :: proc(data: [imdd3.Shape_Type][]imdd3.Debug_Shape, resolution: [2]f32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    total := 0

    for type in imdd3.Shape_Type {
        total += len(data[type])
    }

    if total == 0 {
        return
    }

    projection := projection
    view := view

    gl.UseProgram(shape_renderer.program)
    gl.Uniform2f(shape_renderer.uniforms["u_resolution"].location, resolution[0], resolution[1])
    gl.UniformMatrix4fv(shape_renderer.uniforms["u_projection"].location, 1, false, &projection[0][0])
    gl.UniformMatrix4fv(shape_renderer.uniforms["u_view"].location, 1, false, &view[0][0])

    gl.BindVertexArray(shape_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, shape_renderer.ubo)

    region_size :: size_of(imdd3.Debug_Shape) * imdd3.DEBUG_SHAPE_CAP

    commands: [len(imdd3.Shape_Type)]gl.DrawElementsIndirectCommand

    for type in imdd3.Shape_Type {
        i := int(type)
        instances := data[type]

        if len(instances) > 0 {
            gl.BufferSubData(gl.ARRAY_BUFFER, i * region_size, len(instances) * size_of(imdd3.Debug_Shape), raw_data(instances))
        }

        commands[i] = {
            count = u32(shape_renderer.offset[type].len),
            instanceCount = u32(len(instances)),
            firstIndex = shape_renderer.offset[type].pos,
            baseVertex = 0,
            baseInstance = u32(i) * imdd3.DEBUG_SHAPE_CAP,
        }
    }

    gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, shape_renderer.dibo)
    gl.BufferData(gl.DRAW_INDIRECT_BUFFER, size_of(commands), &commands[0], gl.STREAM_DRAW)

    gl.MultiDrawElementsIndirect(gl.LINES, gl.UNSIGNED_INT, nil, i32(len(imdd3.Shape_Type)), 0)
}

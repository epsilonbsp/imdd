package imdd3_impl_gl

import gl "vendor:OpenGL"

GLSL_VERSION :: "#version 460 core"

Shader_Source :: struct {
    type: gl.Shader_Type,
    source: string,
}

load_shaders :: proc(sources: []Shader_Source, binary_retrievable := false) -> (program_id: u32, ok: bool) {
    shader_ids := make([dynamic]u32, 0, len(sources))
    defer delete(shader_ids)

    defer for id in shader_ids {
        gl.DeleteShader(id)
    }

    for source in sources {
        shader_id := gl.compile_shader_from_source(source.source, source.type) or_return
        append(&shader_ids, shader_id)
    }

    return gl.create_and_link_program(shader_ids[:], binary_retrievable)
}

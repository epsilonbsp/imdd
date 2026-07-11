package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

Renderer :: struct {
    program: u32,
    uniforms: gl.Uniforms,

    vao: u32,
    vbo: u32,
    ibo: u32,

    atlas_tex: u32,
    tex_map: Texture_Map,
}

renderer: Renderer

init :: proc() {
    ok: bool
    renderer.program, ok = gl.load_shaders_source(MAIN_VS, MAIN_FS)
    renderer.uniforms = gl.get_uniforms_from_program(renderer.program)
    assert(ok, "ERROR: Failed to compile main program")

    gl.GenVertexArrays(1, &renderer.vao)
    gl.BindVertexArray(renderer.vao)

    gl.GenBuffers(1, &renderer.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.VERTEX_CAP * size_of(imdd3.Vertex), nil, gl.STREAM_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribIPointer(0, 1, gl.UNSIGNED_INT, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, mode))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, position))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, tex_coord))

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.UNSIGNED_INT, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, tex_index))

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 2, gl.UNSIGNED_INT, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, colors))

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribPointer(5, 4, gl.FLOAT, gl.FALSE, size_of(imdd3.Vertex), offset_of(imdd3.Vertex, params))

    gl.GenBuffers(1, &renderer.ibo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderer.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, imdd3.INDEX_CAP * size_of(u32), nil, gl.STREAM_DRAW)

    renderer.atlas_tex = gen_texture_from_png_bytes(#load("../../../assets/atlas/atlas.png"))

    texture_map_init(&renderer.tex_map, 8)

    // Index 0: white pixel
    white_tex_data := [4]u8{255, 255, 255, 255}
    add_texture(1, 1, white_tex_data[:])
}

destroy :: proc() {
    gl.DeleteProgram(renderer.program)
    gl.destroy_uniforms(renderer.uniforms)

    gl.DeleteVertexArrays(1, &renderer.vao)
    gl.DeleteBuffers(1, &renderer.vbo)
    gl.DeleteBuffers(1, &renderer.ibo)

    gl.DeleteTextures(1, &renderer.atlas_tex)
    texture_map_destroy(&renderer.tex_map)
}

flush :: proc(vertices: []imdd3.Vertex, indices: []u32, projection: matrix[4, 4]f32) {
    if len(vertices) == 0 {
        return
    }

    projection := projection

    gl.UseProgram(renderer.program)
    gl.UniformMatrix4fv(renderer.uniforms["u_projection"].location, 1, false, &projection[0][0])

    gl.BindVertexArray(renderer.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.VERTEX_CAP * size_of(imdd3.Vertex), nil, gl.STREAM_DRAW)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * size_of(imdd3.Vertex), raw_data(vertices))

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderer.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, imdd3.INDEX_CAP * size_of(u32), nil, gl.STREAM_DRAW)
    gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, len(indices) * size_of(u32), raw_data(indices))

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, renderer.atlas_tex)
    gl.Uniform1i(renderer.uniforms["u_atlas_tex"].location, 0)

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, renderer.tex_map.ssbo)

    // gl.Enable(gl.CULL_FACE); defer gl.Disable(gl.CULL_FACE)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)
}

set_clip_rect :: proc(x: i32, y: i32, w: i32, h: i32) {
    viewport: [4]i32; gl.GetIntegerv(gl.VIEWPORT, &viewport[0])

    gl.Enable(gl.SCISSOR_TEST)
    gl.Scissor(x, viewport[3] - y - h, w, h)
}

clear_clip_rect :: proc() {
    gl.Disable(gl.SCISSOR_TEST)
}

add_texture :: proc(width: i32, height: i32, data: []u8) -> u32 {
    return texture_map_add(&renderer.tex_map, gen_texture(width, height, data))
}

remove_texture :: proc(handle: u32) {
    texture_map_remove(&renderer.tex_map, handle)
}

update_texture :: proc(handle: u32, x: i32, y: i32, w: i32, h: i32, data: []u8) {
    assert(int(handle) < len(renderer.tex_map.textures), "ERROR: update_texture handle out of bounds")

    tex := renderer.tex_map.textures[handle]
    gl.BindTexture(gl.TEXTURE_2D, tex)
    gl.TexSubImage2D(gl.TEXTURE_2D, 0, x, y, w, h, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(data))
    gl.BindTexture(gl.TEXTURE_2D, 0)
}

interface :: proc() -> imdd3.Renderer {
    return {
        init = init,
        destroy = destroy,
        flush = flush,
        set_clip_rect = set_clip_rect,
        clear_clip_rect = clear_clip_rect,
        add_texture = add_texture,
        remove_texture = remove_texture,
        update_texture = update_texture,

        shape_init = shape_init,
        shape_destroy = shape_destroy,
        shape_render = shape_render,

        primitive_renderer_init = primitive_renderer_init,
        primitive_renderer_destroy = primitive_renderer_destroy,
        primitive_renderer_render = primitive_renderer_render,

        line_init = line_init,
        line_destroy = line_destroy,
        line_render = line_render,
    }
}

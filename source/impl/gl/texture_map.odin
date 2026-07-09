package imdd33_impl_gl

import gl "vendor:OpenGL"

Texture_Map :: struct {
    textures: [dynamic]u32,
    handles: [dynamic]u64,
    free_list: [dynamic]u32,
    ssbo: u32,
}

texture_map_init :: proc(tm: ^Texture_Map, cap: int) {
    tm.textures = make([dynamic]u32, 0, cap)
    tm.handles = make([dynamic]u64, 0, cap)
    tm.free_list = make([dynamic]u32, 0, cap)
    gl.GenBuffers(1, &tm.ssbo)
}

texture_map_destroy :: proc(tm: ^Texture_Map) {
    for i in 0 ..< len(tm.textures) {
        if tm.textures[i] != 0 {
            gl.MakeTextureHandleNonResidentARB(tm.handles[i])
            gl.DeleteTextures(1, &tm.textures[i])
        }
    }

    gl.DeleteBuffers(1, &tm.ssbo)
    delete(tm.textures)
    delete(tm.handles)
    delete(tm.free_list)
}

texture_map_add :: proc(tm: ^Texture_Map, tex: u32) -> u32 {
    handle := gl.GetTextureHandleARB(tex)
    gl.MakeTextureHandleResidentARB(handle)

    index: u32

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, tm.ssbo)

    if len(tm.free_list) > 0 {
        index = pop(&tm.free_list)
        tm.textures[index] = tex
        tm.handles[index] = handle
        gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, int(index) * size_of(u64), size_of(u64), &tm.handles[index])
    } else {
        index = u32(len(tm.textures))
        append(&tm.textures, tex)
        append(&tm.handles, handle)
        gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(tm.handles) * size_of(u64), raw_data(tm.handles[:]), gl.DYNAMIC_DRAW)
    }

    return index
}

texture_map_remove :: proc(tm: ^Texture_Map, index: u32) {
    assert(int(index) < len(tm.textures), "ERROR: texture_map_remove index out of bounds")

    gl.MakeTextureHandleNonResidentARB(tm.handles[index])
    gl.DeleteTextures(1, &tm.textures[index])

    tm.textures[index] = 0
    tm.handles[index] = 0

    append(&tm.free_list, index)

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, tm.ssbo)
    gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, int(index) * size_of(u64), size_of(u64), &tm.handles[index])
}

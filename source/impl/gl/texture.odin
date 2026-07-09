package imdd33_impl_gl

import "core:image/png"
import gl "vendor:OpenGL"

gen_texture :: proc(width: i32, height: i32, data: []u8) -> u32 {
    tex: u32
    gl.GenTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_2D, tex)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(data))
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.BindTexture(gl.TEXTURE_2D, 0)

    return tex
}

gen_texture_from_png_bytes :: proc(data: []u8) -> u32 {
    image, err := png.load_from_bytes(data, {.alpha_add_if_missing})
    assert(err == nil, "ERROR: Failed to load PNG texture")
    defer png.destroy(image)

    return gen_texture(i32(image.width), i32(image.height), image.pixels.buf[:])
}

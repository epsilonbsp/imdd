package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

GLSL_VERSION :: "#version 460 core"

Renderer :: struct {
    atlas_tex: u32,
    tex_map: Texture_Map,
}

renderer: Renderer

init :: proc() {
    renderer.atlas_tex = gen_texture_from_png_bytes(#load("../../../assets/atlas/atlas.png"))

    texture_map_init(&renderer.tex_map, 8)

    // Index 0: white pixel
    white_tex_data := [4]u8{255, 255, 255, 255}
    add_texture(1, 1, white_tex_data[:])

    line_init()
    triangle_init()
    curve_init()
}

destroy :: proc() {
    gl.DeleteTextures(1, &renderer.atlas_tex)
    texture_map_destroy(&renderer.tex_map)

    line_destroy()
    triangle_destroy()
    curve_destroy()
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

        line_render = line_render,
        triangle_render = triangle_render,
        curve_render = curve_render,
    }
}

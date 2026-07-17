package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

Renderer :: struct {
    viewport: [2]i32,
    projection: matrix[4, 4]f32,
    view: matrix[4, 4]f32,

    atlas_tex: u32,
    tex_map: Texture_Map,
}

renderer: Renderer

init :: proc() {
    renderer.atlas_tex = gen_texture_from_png_bytes(#load("../../../assets/atlas/atlas.png"))

    texture_map_init(&renderer.tex_map, 8)

    white_tex_data := [4]u8{255, 255, 255, 255}
    add_texture(1, 1, white_tex_data[:])

    line_init()
    curve_init()
    triangle_init()
}

destroy :: proc() {
    gl.DeleteTextures(1, &renderer.atlas_tex)
    texture_map_destroy(&renderer.tex_map)

    line_destroy()
    curve_destroy()
    triangle_destroy()
    lineprim_destroy()
    triprim_destroy()
}

prepare_renderer :: proc(viewport: [2]i32, projection: matrix[4, 4]f32, view: matrix[4, 4]f32) {
    renderer.viewport = viewport
    renderer.projection = projection
    renderer.view = view
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

interface :: proc() -> imdd3.Renderer_Interface {
    return {
        init = init,
        destroy = destroy,
        prepare_renderer = prepare_renderer,
        add_texture = add_texture,
        remove_texture = remove_texture,
        update_texture = update_texture,
        line_render = line_render,
        curve_render = curve_render,
        triangle_render = triangle_render,
        lineprim_init = lineprim_init,
        lineprim_render = lineprim_render,
        triprim_init = triprim_init,
        triprim_render = triprim_render,
    }
}

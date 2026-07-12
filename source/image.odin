package imdd3

import "core:image/png"

Sprite :: struct {
    handle: u32,
    left: f32,
    right: f32,
    top: f32,
    bottom: f32,
}

Atlas :: struct {
    width: i32,
    height: i32,
    cursor_x: i32,
    cursor_y: i32,
    shelf_h: i32,
    handle: u32,
}

atlas_create :: proc(width: i32, height: i32) -> Atlas {
    handle := renderer.interface.add_texture(width, height, nil)

    return {
        width = width,
        height = height,
        handle = handle,
    }
}

atlas_destroy :: proc(atlas: ^Atlas) {
    renderer.interface.remove_texture(atlas.handle)
}

atlas_pack :: proc(atlas: ^Atlas, w: i32, h: i32, data: []u8) -> (Sprite, bool) {
    x := atlas.cursor_x
    y := atlas.cursor_y
    shelf_h := atlas.shelf_h

    if x + w > atlas.width {
        x = 0
        y += shelf_h
        shelf_h = 0
    }

    if y + h > atlas.height {
        return {}, false
    }

    atlas.cursor_x = x + w
    atlas.cursor_y = y
    atlas.shelf_h = max(shelf_h, h)

    renderer.interface.update_texture(atlas.handle, x, y, w, h, data)

    fw := f32(atlas.width)
    fh := f32(atlas.height)

    return {
        handle = atlas.handle,
        left = f32(x) / fw,
        right = f32(x + w) / fw,
        top = f32(y) / fh,
        bottom = f32(y + h) / fh,
    }, true
}

atlas_pack_png :: proc(atlas: ^Atlas, data: []u8) -> (Sprite, bool) {
    image, err := png.load_from_bytes(data, {.alpha_add_if_missing})

    if err != nil {
        return {}, false
    }

    defer png.destroy(image)

    return atlas_pack(atlas, i32(image.width), i32(image.height), image.pixels.buf[:])
}

load_sprite_png :: proc(data: []u8) -> (Sprite, bool) {
    image, err := png.load_from_bytes(data, {.alpha_add_if_missing})

    if err != nil {
        return {}, false
    }

    defer png.destroy(image)

    handle := renderer.interface.add_texture(i32(image.width), i32(image.height), image.pixels.buf[:])

    return {
        handle,
        0,
        1,
        0,
        1,
    }, true
}

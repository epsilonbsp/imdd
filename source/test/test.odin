package imdd2_test

import glm "core:math/linalg/glsl"

import imdd3 "../"

Demo_State :: struct {
    forward: [3]f32,
    right: [3]f32,
    atlas: imdd3.Atlas,
    sprite0: imdd3.Sprite,
    sprite1: imdd3.Sprite,
}

demo_state: Demo_State

init_demo :: proc() {
    demo_state.atlas = imdd3.atlas_create(1024, 1024)
    demo_state.sprite0, _ = imdd3.atlas_pack_png(&demo_state.atlas, #load("../../assets/test/test0.png"))
    demo_state.sprite1, _ = imdd3.atlas_pack_png(&demo_state.atlas, #load("../../assets/test/test1.png"))
}

destroy_demo :: proc() {
    imdd3.atlas_destroy(&demo_state.atlas)
}

show_demo :: proc() {
    // imdd3.draw_triangle({}, {128, 0, 0}, {128, 128, 0}, 0xff0000ff)

    // imdd3.draw_rect({}, {0, 0, -1}, {1, 0, 0}, {128, 128}, 0xff0000ff)

    // imdd3.draw_circle({}, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff)
    // imdd3.draw_circle({}, forward, right, 4, 0xff0000ff)

    // imdd3.draw_rrect({}, {0, 0, -1}, {1, 0, 0}, {128, 128}, 0xff0000ff, 4, 0, 0)

    // imdd3.draw_stroke({}, {0, 128, 0}, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff)
    // imdd3.draw_stroke({}, {0, 128, 0}, forward, right, 4, 0xff0000ff)

    // point0 := [3]f32{}
    // point1 := [3]f32{0, 128, 0}
    // point2 := [3]f32{128, 128, 0}

    // imdd3.draw_stroke(point0, point1, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff, 4)
    // imdd3.draw_stroke(point1, point2, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff, 4)
    // imdd3.draw_stroke_cap(point1, point0, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff, .Round)
    // imdd3.draw_stroke_join(point0, point1, point2, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff, .Round)
    // imdd3.draw_stroke_cap(point1, point2, {0, 0, -1}, {1, 0, 0}, 4, 0xff0000ff, .Round)

    // imdd3.draw_stroke_arrow({}, {0, 128, 0}, {0, 0, -1}, {1, 0, 0}, 4, 8, 0xff0000ff)

    // imdd3.draw_grid_xy({}, {128, 128}, 16, 1, 0xff0000ff)
    // imdd3.draw_grid_xz({}, {1024, 1024}, 16, 1, 0xff0000ff)
    // imdd3.draw_grid_yz({}, {128, 128}, 16, 1, 0xff0000ff)

    // imdd3.draw_text({}, {0, 0, -1}, {1, 0, 0}, "Hello, World!", 16, 16, 0xff0000ff)
    // imdd3.draw_text({}, forward, right, "Hello, World!", 16, 16, 0xff0000ff)

    // imdd3.draw_icon({}, {0, 0, -1}, {1, 0, 0}, 16, "close", 0xff0000ff)
    // imdd3.draw_icon({}, forward, right, 16, "close", 0xff0000ff)

    // imdd3.draw_image({}, {0, 0, -1}, {1, 0, 0}, {128, 128}, demo_state.sprite0)
    // imdd3.draw_image({}, forward, right, {128, 128}, demo_state.sprite0)
    // imdd3.draw_rimage({}, {0, 0, -1}, {1, 0, 0}, {128, 128}, demo_state.sprite1, 64)

    // imdd3.draw_line({}, {0, 128, 0}, 4, 0xff0000ff, {0, 1, 0}, {1, 0, 0})
    // imdd3.draw_line({}, {128, 0, 0}, 4, 0xff0000ff, {0, 1, 0}, {1, 0, 0})
    // imdd3.draw_line({}, {0, 128, 0}, 4, 0xff0000ff, 4, 0)

    imdd3.draw_line_strip({
        {0, 0, 0},
        {128, 0, 0},
        {128, 128, 0},
        {0, 128, 0},
    }, 1, 0xff0000ff, .Circle, true, 4)

    // imdd3.draw_curve({0, 0, 0}, {128, 0, 0}, {128, 128, 0}, 2, 0xff0000ff, {0, 0, -1}, 4)
    // imdd3.draw_curve({128, 128, 0}, {128, 256, 0}, {256, 256, 0}, 2, 0xff0000ff, 4)

    // imdd3.draw_half_arc({}, {0, 0, -1}, {1, 0, 0}, 64, 0, glm.PI / 2, 2, 0xff0000ff)

    // imdd3.draw_arc({}, {0, 0, -1}, {1, 0, 0}, 64, 0, glm.PI * 3 / 2, 2, 0xff0000ff)

    // imdd3.draw_ring({}, {0, 0, -1}, {1, 0, 0}, 64, 2, 0xff0000ff)
    // imdd3.draw_ring_dashed({}, {0, 0, -1}, {1, 0, 0}, 64, 2, 0xff0000ff, 16)

    // imdd3.draw_wire_aabb({0, 32, 128}, {64, 64, 64}, 0xebbe60ff)
    // imdd3.draw_wire_cylinder_aa({128, 32, 128}, {32, 64}, 0x9fe685ff)
    // imdd3.draw_wire_cone_aa({256, 32, 128}, {32, 64}, 0x4963e6ff)
    // imdd3.draw_wire_cone_frustum_aa({384, 32, 128}, {32, 64}, 16, 0xe6c25eff)
    // imdd3.draw_wire_sphere({512, 32, 128}, 32, 0xe68ac4ff)
    // imdd3.draw_wire_capsule_aa({640, 32, 128}, {16, 32}, 0xc9a6e6ff)

    // imdd3.draw_aabb({0, 32, -128}, {64, 64, 64}, 0xebbe60ff)
    // imdd3.draw_cylinder_aa({128, 32, -128}, {32, 64}, 0x9fe685ff)
    // imdd3.draw_cone_aa({256, 32, -128}, {32, 64}, 0x4963e6ff)
    // imdd3.draw_cone_frustum_aa({384, 32, -128}, {32, 64}, 16, 0xe6c25eff)
    // imdd3.draw_sphere({512, 32, -128}, 32, 0xe68ac4ff)
    // imdd3.draw_capsule_aa({640, 32, -128}, {16, 32}, 0xc9a6e6ff)

    // projection := glm.mat4Perspective(glm.radians(f32(90)), 1920 / 1080, 8, 128)
    // view := glm.mat4LookAt({0, 0, 0}, {0, 0, -1}, {0, 1, 0})

    // imdd3.frustum(projection * view, 0.5, 0xd1496b_ff)
}

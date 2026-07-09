package imdd3

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

system: Debug_System

// can change to whatever you want
DEBUG_POINT_CAP :: 256
DEBUG_LINE_CAP :: 256
DEBUG_GRID_CAP :: 16
DEBUG_SHAPE_CAP :: 256
DEBUG_FRUSTUM_CAP :: 16
DEBUG_MESH_CAP :: 64
DEBUG_TEXT_CAP :: 1024

Debug_System :: struct {
    // general
    width: i32,
    height: i32,
    framebuffer: Framebuffer,
    depth_texture: u32,

    // shape
    shape_len: i32,
    shape_vao: u32,
    shape_vbo: u32,
    shape_ibo: u32,
    shape_ubo: u32,
    shape_shader: Shader,

    // box
    box_data: [dynamic]Debug_Shape,
    box_len: i32,
    box_offset: Index_Offset,

    // cylinder
    cylinder_data: [dynamic]Debug_Shape,
    cylinder_len: i32,
    cylinder_offset: Index_Offset,

    // cone
    cone_data: [dynamic]Debug_Shape,
    cone_len: i32,
    cone_offset: Index_Offset,

    // sphere
    sphere_data: [dynamic]Debug_Shape,
    sphere_len: i32,
    sphere_offset: Index_Offset,

    // mesh
    mesh_data: [dynamic]^Debug_Mesh,
    mesh_len: i32,
    mesh_shader: Shader,
    mesh_pp_shader: Shader,

    // uniforms
    camera_position: glm.vec3,
    camera_forward: glm.vec3,
    projection: glm.mat4,
    view: glm.mat4,

    light_dir: glm.vec3,
    light_color: glm.vec3,
    ambient_strength: f32,
    specular_strength: f32,
}

debug_init :: proc(width: i32, height: i32) {
    system.width = width
    system.height = height

    system.light_dir = glm.normalize([3]f32{1, 1, 1})
    system.light_color = {1, 1, 1}
    system.ambient_strength = 0.8
    system.specular_strength = 0.5

    make_framebuffer(&system.framebuffer, width, height)

    init_shape_rdr()
    init_mesh_rdr()
}

debug_free :: proc() {
    delete_framebuffer(&system.framebuffer)

    free_shape_rdr()
    free_mesh_rdr()
}

debug_resize :: proc(width: i32, height: i32) {
    system.width = width
    system.height = height
    resize_framebuffer(&system.framebuffer, width, height)
}

debug_prepare :: proc(camera_position: glm.vec3, camera_forward: glm.vec3, projection: glm.mat4, view: glm.mat4) {
    system.camera_position = camera_position
    system.camera_forward = camera_forward
    system.projection = projection
    system.view = view
}

debug_render :: proc() {
    bind_framebuffer(&system.framebuffer)

    gl.Viewport(0, 0, system.framebuffer.width, system.framebuffer.height)
    gl.ClearColor(0, 0, 0, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, system.depth_texture);

    render_mesh_rdr()
    render_shape_rdr()

    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

debug_get_framebuffer :: proc() -> ^Framebuffer {
    return &system.framebuffer
}

debug_set_depth_texture :: proc(texture: u32) {
    system.depth_texture = texture
}

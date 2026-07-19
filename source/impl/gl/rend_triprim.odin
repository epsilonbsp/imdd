package imdd3_impl_gl

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

import imdd3 "../.."

TRIPRIM_LIGHT_DIR :: [3]f32{0.4, 0.8, 0.4}
TRIPRIM_LIGHT_COLOR :: [3]f32{1, 1, 1}
TRIPRIM_AMBIENT_STRENGTH :: 0.3
TRIPRIM_DIFFUSE_STRENGTH :: 0.7
TRIPRIM_SPECULAR_STRENGTH :: 0.2
TRIPRIM_SPECULAR_SHINE :: 32.0

TRIPRIM_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_translation;
    layout(location = 1) in vec4 i_rotation;
    layout(location = 2) in vec3 i_scale;
    layout(location = 3) in float i_radius;
    layout(location = 4) in uint i_color;
    layout(location = 5) in uint i_wire_color;
    layout(location = 6) in uvec2 i_range;

    struct Vertex {
        vec4 anchor;
        vec4 direction;
        vec4 normal;
        vec4 barycentric;
    };

    layout(std430, binding = 0) readonly buffer MeshBuffer {
        Vertex vertex_data[];
    };

    out vec4 v_color;
    out vec4 v_wire_color;
    out vec3 v_barycentric;
    out vec3 v_normal;
    out vec3 v_world_pos;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 rotate(vec3 v, vec4 q) {
        return 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v) + v;
    }

    vec4 unpack_rgba(uint i) {
        return vec4(
            (i >> 24) & 0xFF,
            (i >> 16) & 0xFF,
            (i >> 8) & 0xFF,
            i & 0xFF
        ) / 255.0;
    }

    void main() {
        if (uint(gl_VertexID) >= i_range.y) {
            gl_Position = vec4(0.0);

            return;
        }

        Vertex v = vertex_data[i_range.x + uint(gl_VertexID)];

        vec3 local_position = v.anchor.xyz * i_scale + v.direction.xyz * i_radius;
        vec3 world_position = rotate(local_position, i_rotation) + i_translation;
        gl_Position = u_projection * u_view * vec4(world_position, 1.0);
        v_color = unpack_rgba(i_color);
        v_wire_color = unpack_rgba(i_wire_color);
        v_barycentric = v.barycentric.xyz;
        v_normal = rotate(v.normal.xyz, i_rotation);
        v_world_pos = world_position;
    }
`

TRIPRIM_FS :: GLSL_VERSION + `
#define EDGE_WIDTH 1

in vec4 v_color;
in vec4 v_wire_color;
in vec3 v_barycentric;
in vec3 v_normal;
in vec3 v_world_pos;

out vec4 o_frag_color;

uniform vec3 u_view_pos;
uniform vec3 u_light_dir;
uniform vec3 u_light_color;
uniform float u_mat_ambient_strength;
uniform float u_mat_diffuse_strength;
uniform float u_mat_specular_strength;
uniform float u_mat_specular_shine;

void main() {
    vec3 normal = normalize(v_normal);
    vec3 view_dir = normalize(u_view_pos - v_world_pos);
    vec3 half_dir = normalize(u_light_dir + view_dir);

    vec3 ambient = v_color.rgb * u_light_color * u_mat_ambient_strength;
    vec3 diffuse = v_color.rgb * u_light_color * max(dot(normal, u_light_dir), 0.0) * u_mat_diffuse_strength;
    vec3 specular = u_light_color * pow(max(dot(normal, half_dir), 0.0), u_mat_specular_shine) * u_mat_specular_strength;

    vec3 shaded = pow(ambient + diffuse + specular, vec3(1.0 / 2.2));
    vec4 fill_color = vec4(shaded, v_color.a);

    if (v_wire_color.a > 0.0) {
        vec3 d = fwidth(v_barycentric) * EDGE_WIDTH;
        vec3 f = smoothstep(vec3(0.0), d, v_barycentric);
        float edge = min(min(f.x, f.y), f.z);

        o_frag_color = mix(vec4(v_wire_color.rgb, v_color.a), fill_color, edge);
    } else {
        o_frag_color = fill_color;
    }
}
`

Triprim_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    ibo: u32,
    ssbo: u32,
}

triprim_state: Triprim_State

triprim_init :: proc(vertices: []imdd3.Triprim_Vertex, ranges: [imdd3.Triprim_Type]imdd3.Triprim_Range) {
    Triprim_Vertex :: struct {
        anchor: [4]f32,
        direction: [4]f32,
        normal: [4]f32,
        barycentric: [4]f32,
    }

    ok: bool
    triprim_state.program, ok = load_shaders({{.VERTEX_SHADER, TRIPRIM_VS}, {.FRAGMENT_SHADER, TRIPRIM_FS}})
    assert(ok, "ERROR: Failed to compile triprim program")
    triprim_state.uniforms = gl.get_uniforms_from_program(triprim_state.program)

    vertices_gl := make([]Triprim_Vertex, len(vertices)); defer delete(vertices_gl)

    for vertex, i in vertices {
        vertices_gl[i] = {
            anchor = {vertex.anchor.x, vertex.anchor.y, vertex.anchor.z, 0},
            direction = {vertex.direction.x, vertex.direction.y, vertex.direction.z, 0},
            normal = {vertex.normal.x, vertex.normal.y, vertex.normal.z, 0},
            barycentric = {vertex.barycentric.x, vertex.barycentric.y, vertex.barycentric.z, 0},
        }
    }

    gl.GenBuffers(1, &triprim_state.ssbo)
    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, triprim_state.ssbo)
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(Triprim_Vertex) * len(vertices_gl), raw_data(vertices_gl), gl.STATIC_DRAW)

    gl.GenVertexArrays(1, &triprim_state.vao)
    gl.BindVertexArray(triprim_state.vao)

    gl.GenBuffers(1, &triprim_state.ibo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ibo)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, translation))
    gl.VertexAttribDivisor(0, 1)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, rotation))
    gl.VertexAttribDivisor(1, 1)

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, scale))
    gl.VertexAttribDivisor(2, 1)

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 1, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, radius))
    gl.VertexAttribDivisor(3, 1)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribIPointer(4, 1, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, color))
    gl.VertexAttribDivisor(4, 1)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, 1, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, wire_color))
    gl.VertexAttribDivisor(5, 1)

    gl.EnableVertexAttribArray(6)
    gl.VertexAttribIPointer(6, 2, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, range))
    gl.VertexAttribDivisor(6, 1)
}

triprim_destroy :: proc() {
    gl.DeleteProgram(triprim_state.program)
    gl.destroy_uniforms(triprim_state.uniforms)

    gl.DeleteVertexArrays(1, &triprim_state.vao)
    gl.DeleteBuffers(1, &triprim_state.ibo)
    gl.DeleteBuffers(1, &triprim_state.ssbo)
}

triprim_render :: proc(data: []imdd3.Triprim_Instance, max_vertex_count: u32) {
    if len(data) == 0 {
        return
    }

    gl.UseProgram(triprim_state.program)
    gl.UniformMatrix4fv(triprim_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(triprim_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    inv_view := glm.inverse(renderer.view)
    view_pos := [3]f32{inv_view[3][0], inv_view[3][1], inv_view[3][2]}
    light_dir := glm.normalize(TRIPRIM_LIGHT_DIR)

    gl.Uniform3f(triprim_state.uniforms["u_view_pos"].location, view_pos.x, view_pos.y, view_pos.z)
    gl.Uniform3f(triprim_state.uniforms["u_light_dir"].location, light_dir.x, light_dir.y, light_dir.z)
    gl.Uniform3f(triprim_state.uniforms["u_light_color"].location, TRIPRIM_LIGHT_COLOR.x, TRIPRIM_LIGHT_COLOR.y, TRIPRIM_LIGHT_COLOR.z)
    gl.Uniform1f(triprim_state.uniforms["u_mat_ambient_strength"].location, TRIPRIM_AMBIENT_STRENGTH)
    gl.Uniform1f(triprim_state.uniforms["u_mat_diffuse_strength"].location, TRIPRIM_DIFFUSE_STRENGTH)
    gl.Uniform1f(triprim_state.uniforms["u_mat_specular_strength"].location, TRIPRIM_SPECULAR_STRENGTH)
    gl.Uniform1f(triprim_state.uniforms["u_mat_specular_shine"].location, TRIPRIM_SPECULAR_SHINE)

    gl.BindVertexArray(triprim_state.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ibo)
    gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(imdd3.Triprim_Instance), raw_data(data), gl.STREAM_DRAW)
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, triprim_state.ssbo)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Enable(gl.CULL_FACE); defer gl.Disable(gl.CULL_FACE)
    gl.DrawArraysInstanced(gl.TRIANGLES, 0, i32(max_vertex_count), i32(len(data)))
}

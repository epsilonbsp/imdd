package imdd3_impl_gl

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

import imdd3 "../.."

TRIPRIM_LIGHT_DIR :: glm.vec3{0.4, 0.8, 0.4}
TRIPRIM_LIGHT_COLOR :: glm.vec3{1, 1, 1}
TRIPRIM_AMBIENT_STRENGTH :: 0.3
TRIPRIM_DIFFUSE_STRENGTH :: 0.7
TRIPRIM_SPECULAR_STRENGTH :: 0.2
TRIPRIM_SPECULAR_SHINE :: 32.0

TRIPRIM_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_anchor;
    layout(location = 1) in vec3 i_direction;
    layout(location = 2) in vec3 i_normal;
    layout(location = 3) in vec3 i_barycentric;
    layout(location = 4) in vec3 i_translation;
    layout(location = 5) in vec4 i_rotation;
    layout(location = 6) in vec3 i_scale;
    layout(location = 7) in float i_radius;
    layout(location = 8) in uint i_color;
    layout(location = 9) in uint i_wire_color;

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
        vec3 local_position = i_anchor * i_scale + i_direction * i_radius;
        vec3 world_position = rotate(local_position, i_rotation) + i_translation;
        gl_Position = u_projection * u_view * vec4(world_position, 1.0);
        v_color = unpack_rgba(i_color);
        v_wire_color = unpack_rgba(i_wire_color);
        v_barycentric = i_barycentric;
        v_normal = rotate(i_normal, i_rotation);
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
    vbo: u32,
    ubo: u32,
    dibo: u32,

    ranges: [imdd3.Triprim_Type]imdd3.Triprim_Range,
}

triprim_state: Triprim_State

triprim_init :: proc(vertices: []imdd3.Triprim_Vertex, ranges: [imdd3.Triprim_Type]imdd3.Triprim_Range) {
    triprim_state.ranges = ranges

    ok: bool
    triprim_state.program, ok = load_shaders({{.VERTEX_SHADER, TRIPRIM_VS}, {.FRAGMENT_SHADER, TRIPRIM_FS}})
    assert(ok, "ERROR: Failed to compile triprim program")
    triprim_state.uniforms = gl.get_uniforms_from_program(triprim_state.program)

    gl.GenVertexArrays(1, &triprim_state.vao)
    gl.BindVertexArray(triprim_state.vao)

    gl.GenBuffers(1, &triprim_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Triprim_Vertex) * len(vertices), raw_data(vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, anchor))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, direction))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, normal))

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Vertex), offset_of(imdd3.Triprim_Vertex, barycentric))

    gl.GenBuffers(1, &triprim_state.ubo)
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(imdd3.Triprim_Instance) * imdd3.TRIPRIM_CAP * len(imdd3.Triprim_Type), nil, gl.DYNAMIC_DRAW)

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, translation))
    gl.VertexAttribDivisor(4, 1)

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribPointer(5, 4, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, rotation))
    gl.VertexAttribDivisor(5, 1)

    gl.EnableVertexAttribArray(6)
    gl.VertexAttribPointer(6, 3, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, scale))
    gl.VertexAttribDivisor(6, 1)

    gl.EnableVertexAttribArray(7)
    gl.VertexAttribPointer(7, 1, gl.FLOAT, false, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, radius))
    gl.VertexAttribDivisor(7, 1)

    gl.EnableVertexAttribArray(8)
    gl.VertexAttribIPointer(8, 1, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, color))
    gl.VertexAttribDivisor(8, 1)

    gl.EnableVertexAttribArray(9)
    gl.VertexAttribIPointer(9, 1, gl.UNSIGNED_INT, size_of(imdd3.Triprim_Instance), offset_of(imdd3.Triprim_Instance, wire_color))
    gl.VertexAttribDivisor(9, 1)

    gl.GenBuffers(1, &triprim_state.dibo)
}

triprim_destroy :: proc() {
    gl.DeleteProgram(triprim_state.program)
    gl.destroy_uniforms(triprim_state.uniforms)

    gl.DeleteVertexArrays(1, &triprim_state.vao)
    gl.DeleteBuffers(1, &triprim_state.vbo)
    gl.DeleteBuffers(1, &triprim_state.ubo)
    gl.DeleteBuffers(1, &triprim_state.dibo)
}

triprim_render :: proc(data: [imdd3.Triprim_Type][]imdd3.Triprim_Instance) {
    total := 0

    for type in imdd3.Triprim_Type {
        total += len(data[type])
    }

    if total == 0 {
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
    gl.BindBuffer(gl.ARRAY_BUFFER, triprim_state.ubo)
    gl.BufferData(gl.ARRAY_BUFFER, total * size_of(imdd3.Triprim_Instance), nil, gl.STREAM_DRAW)

    commands: [len(imdd3.Triprim_Type)]gl.DrawArraysIndirectCommand

    offset := 0

    for type in imdd3.Triprim_Type {
        i := int(type)
        instances := data[type]

        if len(instances) > 0 {
            gl.BufferSubData(gl.ARRAY_BUFFER, offset * size_of(imdd3.Triprim_Instance), len(instances) * size_of(imdd3.Triprim_Instance), raw_data(instances))
        }

        commands[i] = {
            count = u32(triprim_state.ranges[type].count),
            instanceCount = u32(len(instances)),
            first = triprim_state.ranges[type].first,
            baseInstance = u32(offset),
        }

        offset += len(instances)
    }

    gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, triprim_state.dibo)
    gl.BufferData(gl.DRAW_INDIRECT_BUFFER, size_of(commands), &commands[0], gl.STREAM_DRAW)

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Enable(gl.CULL_FACE); defer gl.Disable(gl.CULL_FACE)
    gl.MultiDrawArraysIndirect(gl.TRIANGLES, nil, i32(len(imdd3.Triprim_Type)), 0)
}

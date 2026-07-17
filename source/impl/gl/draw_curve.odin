package imdd3_impl_gl

import gl "vendor:OpenGL"

import imdd3 "../.."

CURVE_VS :: GLSL_VERSION + `
    layout(location = 0) in vec3 i_position;
    layout(location = 1) in float i_radius;
    layout(location = 2) in float i_weight;
    layout(location = 3) in uint i_color;
    layout(location = 4) in float i_distance;
    layout(location = 5) in float i_dash;
    layout(location = 6) in vec3 i_normal;

    out Vertex_Data {
        float radius;
        float weight;
        uint color;
        float distance;
        float dash;
        vec3 normal;
    } v_data;

    void main() {
        gl_Position = vec4(i_position, 1.0);
        v_data.radius = i_radius;
        v_data.weight = i_weight;
        v_data.color = i_color;
        v_data.distance = i_distance;
        v_data.dash = i_dash;
        v_data.normal = i_normal;
    }
`

CURVE_TCS :: GLSL_VERSION + `
    layout(vertices = 3) out;

    in Vertex_Data {
        float radius;
        float weight;
        uint color;
        float distance;
        float dash;
        vec3 normal;
    } v_data_in[];

    out Vertex_Data {
        float radius;
        float weight;
        uint color;
        float distance;
        float dash;
        vec3 normal;
    } v_data_out[];

    #define CURVE_SEGMENTS 32.0

    void main() {
        if (gl_InvocationID == 0) {
            gl_TessLevelOuter[0] = 1.0;
            gl_TessLevelOuter[1] = CURVE_SEGMENTS;
        }

        gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
        v_data_out[gl_InvocationID].radius = v_data_in[gl_InvocationID].radius;
        v_data_out[gl_InvocationID].weight = v_data_in[gl_InvocationID].weight;
        v_data_out[gl_InvocationID].color = v_data_in[gl_InvocationID].color;
        v_data_out[gl_InvocationID].distance = v_data_in[gl_InvocationID].distance;
        v_data_out[gl_InvocationID].dash = v_data_in[gl_InvocationID].dash;
        v_data_out[gl_InvocationID].normal = v_data_in[gl_InvocationID].normal;
    }
`

CURVE_TES :: GLSL_VERSION + `
    layout(isolines, equal_spacing) in;

    in Vertex_Data {
        float radius;
        float weight;
        uint color;
        float distance;
        float dash;
        vec3 normal;
    } v_data[];

    out Geometry_Data {
        float radius;
        vec4 color;
        vec3 tangent;
        float distance;
        float dash;
        vec3 normal;
    } v_gd;

    vec4 unpack_rgba(uint i) {
        return vec4(
            float((i >> 24) & 0xFFu),
            float((i >> 16) & 0xFFu),
            float((i >> 8) & 0xFFu),
            float(i & 0xFFu)
        ) / 255.0;
    }

    float bezier_speed(vec3 p0, vec3 p1, vec3 p2, float w0, float w1, float w2, float t) {
        float b0 = (1.0 - t) * (1.0 - t) * w0;
        float b1 = 2.0 * (1.0 - t) * t * w1;
        float b2 = t * t * w2;
        float denom = b0 + b1 + b2;

        vec3 numer = b0 * p0 + b1 * p1 + b2 * p2;

        float db0 = -2.0 * (1.0 - t) * w0;
        float db1 = 2.0 * w1 * (1.0 - 2.0 * t);
        float db2 = 2.0 * t * w2;
        float ddenom = db0 + db1 + db2;

        vec3 dnumer = db0 * p0 + db1 * p1 + db2 * p2;

        return length(dnumer * denom - numer * ddenom) / (denom * denom);
    }

    float arc_length(vec3 p0, vec3 p1, vec3 p2, float w0, float w1, float w2, float t) {
        const float X1 = 0.7745966692;
        const float W0 = 0.5555555556;
        const float W1 = 0.8888888889;

        float half_t = t * 0.5;

        float s0 = bezier_speed(p0, p1, p2, w0, w1, w2, half_t * (1.0 - X1));
        float s1 = bezier_speed(p0, p1, p2, w0, w1, w2, half_t);
        float s2 = bezier_speed(p0, p1, p2, w0, w1, w2, half_t * (1.0 + X1));

        return half_t * (W0 * s0 + W1 * s1 + W0 * s2);
    }

    void main() {
        float t = gl_TessCoord.x;

        vec3 p0 = gl_in[0].gl_Position.xyz;
        vec3 p1 = gl_in[1].gl_Position.xyz;
        vec3 p2 = gl_in[2].gl_Position.xyz;

        float w0 = v_data[0].weight;
        float w1 = v_data[1].weight;
        float w2 = v_data[2].weight;

        float b0 = (1.0 - t) * (1.0 - t) * w0;
        float b1 = 2.0 * (1.0 - t) * t * w1;
        float b2 = t * t * w2;
        float denom = b0 + b1 + b2;

        vec3 numer = b0 * p0 + b1 * p1 + b2 * p2;
        vec3 pos = numer / denom;

        float db0 = -2.0 * (1.0 - t) * w0;
        float db1 = 2.0 * w1 * (1.0 - 2.0 * t);
        float db2 = 2.0 * t * w2;
        float ddenom = db0 + db1 + db2;

        vec3 dnumer = db0 * p0 + db1 * p1 + db2 * p2;
        vec3 tangent = normalize(dnumer * denom - numer * ddenom);

        float radius = (b0 * v_data[0].radius + b1 * v_data[1].radius + b2 * v_data[2].radius) / denom;
        vec4 color = (b0 * unpack_rgba(v_data[0].color) + b1 * unpack_rgba(v_data[1].color) + b2 * unpack_rgba(v_data[2].color)) / denom;

        gl_Position = vec4(pos, 1.0);
        v_gd.radius = radius;
        v_gd.color = color;
        v_gd.tangent = tangent;
        v_gd.distance = v_data[0].dash > 0.0 ? v_data[0].distance + arc_length(p0, p1, p2, w0, w1, w2, t) : 0.0;
        v_gd.dash = v_data[0].dash;
        v_gd.normal = v_data[0].normal;
    }
`

CURVE_GS :: GLSL_VERSION + `
    layout(lines) in;
    layout(triangle_strip, max_vertices = 4) out;

    in Geometry_Data {
        float radius;
        vec4 color;
        vec3 tangent;
        float distance;
        float dash;
        vec3 normal;
    } v_gd[];

    out vec4 v_color;
    out float v_distance;
    flat out float v_dash;

    uniform mat4 u_projection;
    uniform mat4 u_view;

    vec3 screen_perp(vec3 view_pos, vec3 view_tangent) {
        vec4 clip_a = u_projection * vec4(view_pos, 1.0);
        vec4 clip_b = u_projection * vec4(view_pos + view_tangent * 0.01, 1.0);

        vec2 screen_a = clip_a.xy / clip_a.w;
        vec2 screen_b = clip_b.xy / clip_b.w;

        vec2 screen_dir = normalize(screen_b - screen_a);

        return normalize(vec3(-screen_dir.y, screen_dir.x, 0.0));
    }

    vec3 compute_perp(vec3 view_pos, vec3 world_tangent, vec3 view_tangent, vec3 normal) {
        if (dot(normal, normal) > 0.0001) {
            vec3 world_perp = normalize(cross(normal, world_tangent));

            return normalize(mat3(u_view) * world_perp);
        }

        return screen_perp(view_pos, view_tangent);
    }

    void main() {
        vec4 view0 = u_view * gl_in[0].gl_Position;
        vec4 view1 = u_view * gl_in[1].gl_Position;

        vec3 tangent0 = normalize(mat3(u_view) * v_gd[0].tangent);
        vec3 tangent1 = normalize(mat3(u_view) * v_gd[1].tangent);

        vec3 perp0 = compute_perp(view0.xyz, v_gd[0].tangent, tangent0, v_gd[0].normal);
        vec3 perp1 = compute_perp(view1.xyz, v_gd[1].tangent, tangent1, v_gd[1].normal);

        vec3 offset0 = perp0 * v_gd[0].radius;
        vec3 offset1 = perp1 * v_gd[1].radius;

        v_dash = v_gd[0].dash;

        gl_Position = u_projection * vec4(view0.xyz + offset0, 1.0);
        v_color = v_gd[0].color; v_distance = v_gd[0].distance;
        EmitVertex();

        gl_Position = u_projection * vec4(view0.xyz - offset0, 1.0);
        v_color = v_gd[0].color; v_distance = v_gd[0].distance;
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz + offset1, 1.0);
        v_color = v_gd[1].color; v_distance = v_gd[1].distance;
        EmitVertex();

        gl_Position = u_projection * vec4(view1.xyz - offset1, 1.0);
        v_color = v_gd[1].color; v_distance = v_gd[1].distance;
        EmitVertex();

        EndPrimitive();
    }
`

CURVE_FS :: GLSL_VERSION + `
    in vec4 v_color;
    in float v_distance;
    flat in float v_dash;

    out vec4 o_frag_color;

    void main() {
        if (v_dash > 0.0 && mod(v_distance, v_dash * 2.0) > v_dash) {
            discard;
        }

        o_frag_color = v_color;
    }
`

Curve_State :: struct {
    program: u32,
    uniforms: gl.Uniforms,
    vao: u32,
    vbo: u32,
}

curve_state: Curve_State

curve_init :: proc() {
    ok: bool
    curve_state.program, ok = load_shaders({
        {.VERTEX_SHADER, CURVE_VS},
        {.TESS_CONTROL_SHADER, CURVE_TCS},
        {.TESS_EVALUATION_SHADER, CURVE_TES},
        {.GEOMETRY_SHADER, CURVE_GS},
        {.FRAGMENT_SHADER, CURVE_FS},
    })
    assert(ok, "ERROR: Failed to compile curve program")
    curve_state.uniforms = gl.get_uniforms_from_program(curve_state.program)

    gl.GenVertexArrays(1, &curve_state.vao)
    gl.BindVertexArray(curve_state.vao)

    gl.GenBuffers(1, &curve_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, curve_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.CURVE_VERTEX_CAP * size_of(imdd3.Curve_Vertex), nil, gl.STREAM_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, position))

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 1, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, radius))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 1, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, weight))

    gl.EnableVertexAttribArray(3)
    gl.VertexAttribIPointer(3, 1, gl.UNSIGNED_INT, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, color))

    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 1, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, distance))

    gl.EnableVertexAttribArray(5)
    gl.VertexAttribPointer(5, 1, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, dash))

    gl.EnableVertexAttribArray(6)
    gl.VertexAttribPointer(6, 3, gl.FLOAT, false, size_of(imdd3.Curve_Vertex), offset_of(imdd3.Curve_Vertex, normal))

    gl.PatchParameteri(gl.PATCH_VERTICES, 3)
}

curve_destroy :: proc() {
    gl.DeleteProgram(curve_state.program)
    gl.destroy_uniforms(curve_state.uniforms)
    gl.DeleteVertexArrays(1, &curve_state.vao)
    gl.DeleteBuffers(1, &curve_state.vbo)
}

curve_render :: proc(vertices: []imdd3.Curve_Vertex) {
    if len(vertices) < 3 {
        return
    }

    gl.UseProgram(curve_state.program)
    gl.UniformMatrix4fv(curve_state.uniforms["u_projection"].location, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(curve_state.uniforms["u_view"].location, 1, false, &renderer.view[0][0])

    gl.BindVertexArray(curve_state.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, curve_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, imdd3.CURVE_VERTEX_CAP * size_of(imdd3.Curve_Vertex), nil, gl.STREAM_DRAW)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * size_of(imdd3.Curve_Vertex), raw_data(vertices))

    gl.Enable(gl.DEPTH_TEST); defer gl.Disable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL); defer gl.DepthFunc(gl.LESS)
    gl.Enable(gl.BLEND); defer gl.Disable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    gl.DrawArrays(gl.PATCHES, 0, i32(len(vertices)))
}

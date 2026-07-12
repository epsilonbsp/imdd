# IMDD
Immediate mode debug draw for 3D

## API Reference
```odin
draw_line :: proc(point0: [3]f32, point1: [3]f32, width: f32, color: u32, is_rounded := false)
draw_line_cap :: proc(point0: [3]f32, dir: [3]f32, width: f32, color: u32, cap_type: Line_Cap_Type = .None)
draw_line_strip :: proc(points: [][3]f32, width: f32, color: u32, cap_type: Line_Cap_Type = .None, is_looped := false)

draw_curve :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, width: f32, color: u32)
draw_half_arc :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, angle0: f32, angle1: f32, width: f32, color: u32)
draw_arc :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, angle0: f32, angle1: f32, width: f32, color: u32)
draw_ring :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, width: f32, color: u32)

draw_triangle :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, color: u32)
draw_rect :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, color: u32)
draw_circle :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, radius: f32, color: u32)
draw_rrect :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, fill_color: u32, radius: f32 = 0, stroke_width: f32 = 0, stroke_color: u32)
draw_stroke :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32)
draw_stroke_join :: proc(point0: [3]f32, point1: [3]f32, point2: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, type: Stroke_Join_Type, miter_limit: f32 = 4)
draw_stroke_cap :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, color: u32, type: Stroke_Cap_Type)
draw_stroke_arrow :: proc(point0: [3]f32, point1: [3]f32, normal: [3]f32, tangent: [3]f32, width: f32, head_size: f32, color: u32)
draw_grid :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32)
draw_grid_xy :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32)
draw_grid_xz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32)
draw_grid_yz :: proc(center: [3]f32, size: [2]f32, cell_size: [2]f32, line_width: f32, color: u32)
draw_text :: proc(position: [3]f32, normal: [3]f32, tangent: [3]f32, text: string, font_size: f32, line_height: f32, color: u32, alignment: [2]f32 = {}, clip_max_x: f32 = max(f32))
draw_icon :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: f32, key: string, color: u32)
draw_image :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, sprite: Sprite)
draw_rimage :: proc(center: [3]f32, normal: [3]f32, tangent: [3]f32, size: [2]f32, sprite: Sprite, radius: f32 = 0)

draw_wire_aabb :: proc(position: glm.vec3, size: glm.vec3, color: u32)
draw_wire_aabb_bounds :: proc(min: glm.vec3, max: glm.vec3, color: u32)
draw_wire_obb :: proc(position: glm.vec3, size: glm.vec3, rotation: glm.vec3, color: u32)
draw_wire_cylinder_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32)
draw_wire_cylinder_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32)
draw_wire_cylinder_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32)
draw_wire_cone_aa :: proc(position: glm.vec3, size: glm.vec2, color: u32)
draw_wire_cone_o :: proc(position: glm.vec3, size: glm.vec2, rotation: glm.vec3, color: u32)
draw_wire_cone_ab :: proc(start: glm.vec3, end: glm.vec3, radius: f32, color: u32)
draw_wire_sphere :: proc(position: glm.vec3, radius: f32, color: u32)

draw_aabb :: proc(position: [3]f32, size: [3]f32, color: u32)

frustum :: proc(proj_view: matrix[4, 4]f32, line_width: f32, color: u32)
```

shader_type canvas_item;
// Crop both the atmosphere and network inside a cyan Panel's rounded inner edge.
uniform vec2 panel_size = vec2(1280.0, 650.0);
uniform float corner_radius = 23.0;
varying vec2 board_local;
void vertex() {
    board_local = VERTEX;
}
void fragment() {
    vec2 halfsize = panel_size * 0.5;
    vec2 q = abs(board_local - halfsize) - (halfsize - vec2(corner_radius));
    float outside = length(max(q, vec2(0.0))) + min(max(q.x,q.y),0.0) - corner_radius;
    COLOR.a *= 1.0 - smoothstep(-1.2, 1.2, outside);
}

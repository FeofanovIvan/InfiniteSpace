shader_type canvas_item;
render_mode unshaded;

// Screen-space rounded clipping even when the image itself extends far beyond
// the stage because it is scaled with COVER rather than squashed.
uniform vec2 stage_screen_origin = vec2(0.0, 0.0);
uniform vec2 stage_screen_size = vec2(1200.0, 700.0);
uniform float radius = 27.0;

void fragment() {
    vec2 xy = SCREEN_UV / SCREEN_PIXEL_SIZE - stage_screen_origin;
    vec2 half_size = stage_screen_size * 0.5;
    vec2 q = abs(xy - half_size) - (half_size - vec2(radius));
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    COLOR.a *= 1.0 - smoothstep(-1.0, 1.0, distance_to_edge);
}

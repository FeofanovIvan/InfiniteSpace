shader_type canvas_item;
render_mode unshaded;

// One image layer inside the Evolution stage. The stage has a 28px corner
// radius plus 3px frame, hence the background has an inner radius of 25px.
// Local VERTEX positions remain rectangular even when TextureRect uses
// STRETCH_KEEP_ASPECT_COVERED and crops the source image on narrow screens.
uniform vec2 panel_size = vec2(1200.0, 550.0);
uniform float corner_radius = 25.0;

varying vec2 local_position;

void vertex() {
    local_position = VERTEX;
}

void fragment() {
    float r = min(corner_radius, min(panel_size.x, panel_size.y) * 0.5);
    vec2 q = abs(local_position - panel_size * 0.5) - (panel_size * 0.5 - vec2(r));
    float signed_distance = length(max(q, vec2(0.0)))
        + min(max(q.x, q.y), 0.0) - r;
    // Keep original texture/colors; only fade the image outside the rounded mask.
    COLOR.a *= 1.0 - smoothstep(-1.25, 1.25, signed_distance);
}

shader_type canvas_item;
render_mode unshaded;

// Only facial sprites. The already approved liquid body shader and its alpha
// behaviour are completely untouched.
uniform float curve_strength : hint_range(0.0, 0.3) = 0.12;
uniform float side_bend : hint_range(-1.0, 1.0) = 0.0;
varying vec4 sprite_tint;

void vertex() {
    sprite_tint = COLOR;
}

void fragment() {
    vec2 uv = UV;
    float x = uv.x * 2.0 - 1.0;
    float y = uv.y * 2.0 - 1.0;
    uv.x += (curve_strength * 0.10) * x * (1.0 - x*x);
    uv.y += side_bend * 0.026 * x * (1.0 - y*y);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        COLOR = texture(TEXTURE, uv) * sprite_tint;
    }
}

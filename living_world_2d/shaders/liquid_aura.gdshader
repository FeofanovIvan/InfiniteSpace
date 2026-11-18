shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float elapsed = 0.0;
uniform float activity = 0.8;
uniform float response_power = 0.0;
uniform vec4 glow_color : source_color = vec4(0.18, 0.73, 0.86, 1.0);

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    float theta = atan(p.y, p.x);
    float r = length(p);
    float slow = sin(theta * 6.0 - elapsed * 0.42) * 0.012 * activity;
    float r0 = 0.755 + slow;
    float narrow = exp(-pow((r - r0) / 0.036, 2.0));
    float wide = exp(-pow((r - r0) / 0.125, 2.0));
    float breath = 0.84 + 0.16 * sin(elapsed * 0.55);
    float alpha = clamp((0.15 * narrow + 0.11 * wide) * breath * (1.0 + response_power * 0.9), 0.0, 0.40);
    COLOR = vec4(glow_color.rgb, alpha);
}

shader_type canvas_item;
render_mode unshaded, blend_mix;

// v45: Moving inner luminous seed (and softer wake) masked by the original
// spacecraft texture. No black ring, no new external blob or painted hull.
uniform float light_phase = 0.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.7;
uniform vec4 light_tint : source_color = vec4(0.52, 0.83, 1.0, 1.0);
uniform float motion_rate : hint_range(0.2, 2.0) = 1.0;

void fragment() {
    vec4 hull = texture(TEXTURE, UV);
    float t = TIME * motion_rate;
    vec2 light_pos = vec2(
        0.5 + 0.205 * sin(t * 0.47 + light_phase),
        0.5 + 0.115 * sin(t * 0.63 + light_phase * 1.7)
    );
    vec2 wake_pos = vec2(
        0.5 + 0.19 * sin(t * 0.47 + light_phase - 0.48),
        0.5 + 0.11 * sin(t * 0.63 + light_phase * 1.7 - 0.48)
    );
    float d = length(UV - light_pos);
    float d_wake = length(UV - wake_pos);
    float core = 1.0 - smoothstep(0.002, 0.017, d);
    float aura = 1.0 - smoothstep(0.022, 0.145, d);
    float trail = 1.0 - smoothstep(0.012, 0.085, d_wake);
    float pulse = 0.79 + 0.21 * sin(t * 2.3 + light_phase);
    // Only illuminated where the source hull exists, respecting its alpha.
    float inside = smoothstep(0.08, 0.64, hull.a);
    float light = brightness * pulse * inside;
    vec3 local_light = mix(hull.rgb, light_tint.rgb, 0.66);
    vec3 illuminated = hull.rgb * (1.0 + 0.21 * aura * light);
    illuminated += local_light * (0.55 * core + 0.26 * aura + 0.14 * trail) * light;
    // A very small bright moving point, not a large solid disk.
    COLOR = vec4(min(illuminated, vec3(1.0)), hull.a * 0.96);
}

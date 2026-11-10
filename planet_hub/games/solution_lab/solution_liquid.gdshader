shader_type canvas_item;
render_mode blend_mix;

uniform vec4 solution_color : source_color = vec4(0.4, 0.75, 1.0, 1.0);
uniform float fill_level : hint_range(0.0, 1.0) = 0.78;

void fragment() {
    float mask = texture(TEXTURE, UV).a;
    float surface = mix(0.95, 0.11, clamp(fill_level, 0.0, 1.0));
    float ripple = sin(UV.x * 35.0 + TIME * 3.0) * 0.003;
    float submerged = smoothstep(surface - 0.006, surface + 0.006, UV.y + ripple);
    float highlight = exp(-abs(UV.y - surface) * 220.0) * 0.27;

    float ring = 0.0;
    for (int i = 0; i < 8; i++) {
        float seed = float(i) + 1.0;
        float bx = 0.22 + 0.56 * fract(sin(seed * 17.41) * 45123.12);
        float phase = fract(TIME * (0.11 + 0.011 * mod(seed, 4.0)) + seed * 0.123);
        float by = 0.90 - phase * (0.90 - surface);
        float rr = 0.009 + 0.006 * fract(seed * 0.37);
        float dist = distance(UV * vec2(1.0, 1.15), vec2(bx, by * 1.15));
        float outer = 1.0 - smoothstep(rr - 0.002, rr + 0.002, dist);
        float inner = 1.0 - smoothstep(rr - 0.007, rr - 0.003, dist);
        ring = max(ring, max(0.0, outer - inner));
    }
    vec3 color = mix(solution_color.rgb * 0.84, solution_color.rgb, UV.x * 0.42);
    color = mix(color, vec3(1.0), clamp(highlight + ring * 0.43, 0.0, 0.60));
    COLOR = vec4(color, mask * submerged * 0.93 * solution_color.a);
}

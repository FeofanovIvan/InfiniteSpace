shader_type canvas_item;
render_mode unshaded, blend_mix;

// For a 780px corona quad around a 500px surface quad: 500/780.
uniform float solar_radius : hint_range(0.1, 0.95, 0.005) = 0.641;
uniform float corona_strength : hint_range(0.0, 2.0, 0.05) = 1.0;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float r = length(p);
    float angle = atan(p.y, p.x);
    float hairs = sin(angle * 17.0 + TIME * 0.24 + sin(angle * 6.0) * 1.8);
    float hairs2 = sin(angle * 31.0 - TIME * 0.15);
    float jagged_edge = solar_radius + 0.015 * hairs + 0.011 * hairs2;
    float distance_from_edge = max(0.0, r - jagged_edge);
    float halo = 0.35 * exp(-distance_from_edge * 15.0)
               + 0.19 * exp(-distance_from_edge * 5.2);
    float filaments = pow(0.5 + 0.5 * hairs, 8.0) * exp(-distance_from_edge * 6.0) * 0.17;
    float alpha = (halo + filaments) * smoothstep(solar_radius * 0.91, solar_radius * 1.05, r);
    alpha *= 1.0 - smoothstep(0.96, 1.18, r);
    alpha = clamp(alpha * corona_strength, 0.0, 0.78);
    vec3 corona_color = mix(vec3(1.0, 0.33, 0.045), vec3(1.0, 0.65, 0.18),
                             exp(-distance_from_edge * 12.0));
    COLOR = vec4(corona_color, alpha);
}

shader_type canvas_item;
render_mode unshaded, blend_mix;
// Subtle filaments connecting the outer storm back to the living surface.
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
uniform float response_energy : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cyan_color : source_color = vec4(0.44, 0.98, 0.91, 1.0);
uniform vec4 violet_color : source_color = vec4(0.67, 0.49, 1.0, 1.0);
void fragment() {
    vec2 p = (UV - 0.5) * 4.10;
    float r = length(p);
    if (r < 0.97 || r > 1.39 || intensity < 0.001) { COLOR = vec4(0.0); }
    else {
        float a = atan(p.y, p.x);
        float t = elapsed;
        float curl = a * 5.0 - log(max(r, 0.5)) * 9.0 - t * 0.14;
        float filament = pow(max(0.0, cos(curl)), 24.0);
        float envelope = smoothstep(0.99, 1.06, r) * (1.0 - smoothstep(1.20, 1.39, r));
        float glow = filament * envelope * (0.22 + 0.18 * sin(a * 4.0 - t * 0.13)) * intensity;
        vec3 c = mix(cyan_color.rgb, violet_color.rgb, 0.5 + 0.5 * sin(a * 2.0 + t * 0.03));
        COLOR = vec4(c, clamp(glow * (1.0 + response_energy * 0.65), 0.0, 0.44));
    }
}

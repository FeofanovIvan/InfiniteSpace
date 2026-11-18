shader_type canvas_item;
render_mode unshaded, blend_mix;
// Slow, thick pearlescent ribbons, NOT regular gas cloud spiral galaxy arms.
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
uniform float response_energy : hint_range(0.0, 1.0) = 0.0;
uniform float detail_level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 cyan_color : source_color = vec4(0.24, 0.89, 0.93, 1.0);
uniform vec4 violet_color : source_color = vec4(0.52, 0.42, 0.89, 1.0);

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 4.10;
    float r = length(p);
    if (r < 0.995 || r > 1.88 || intensity < 0.001) { COLOR = vec4(0.0); }
    else {
        float a = atan(p.y, p.x);
        float t = elapsed;
        float wobble = 0.22 * sin(a * 7.0 + t * 0.085) + 0.12 * sin(a * 11.0 - t * 0.13);
        float coordinate = a * 3.0 - 6.7 * log(max(r, 0.8)) - t * 0.15 + wobble;
        float ribbon = pow(max(0.0, cos(coordinate)), 11.0);
        float second = pow(max(0.0, cos(coordinate + 0.43)), 17.0) * 0.40;
        float edge = smoothstep(1.015, 1.11, r) * (1.0 - smoothstep(1.65, 1.88, r));
        float stretch = 0.63 + 0.37 * sin(a * 5.0 - t * 0.07) * sin(a * 5.0 - t * 0.07);
        float glow = (ribbon * 0.50 + second * 0.27) * edge * stretch * intensity;
        glow *= 1.0 + response_energy * 0.8;
        float fine = 0.0;
        if (detail_level > 0.5) { fine = pow(max(0.0, cos(coordinate * 2.1 + 0.6)), 24.0) * 0.11 * edge; }
        vec3 pigment = mix(violet_color.rgb, cyan_color.rgb, clamp(0.50 + 0.45 * sin(a * 2.0 - t * 0.035), 0.0, 1.0));
        COLOR = vec4(pigment, clamp(glow + fine, 0.0, 0.76));
    }
}

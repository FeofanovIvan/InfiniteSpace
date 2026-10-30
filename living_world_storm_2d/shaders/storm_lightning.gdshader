shader_type canvas_item;
render_mode unshaded, blend_mix;
// Smooth soft arcs; no fast flashing or strobing (age 3-6).
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
uniform float response_energy : hint_range(0.0, 1.0) = 0.0;
uniform float burst_power : hint_range(0.0, 1.0) = 0.0;
uniform float burst_direction = -0.8;
uniform vec4 cyan_color : source_color = vec4(0.65, 1.0, 1.0, 1.0);

float angle_gap(float a, float b) { return atan(sin(a - b), cos(a - b)); }
float bell(float d, float s) { float u = d / s; return exp(-u * u); }
void fragment() {
    vec2 p = (UV - 0.5) * 4.10;
    float r = length(p);
    if (r < 1.045 || r > 1.86 || intensity < 0.001) { COLOR = vec4(0.0); }
    else {
        float a = atan(p.y, p.x);
        float phase = fract(elapsed * 0.079);
        // A slow fading pulse, never a sharp on/off flash.
        float pulse = smoothstep(0.06, 0.20, phase) * (1.0 - smoothstep(0.39, 0.64, phase));
        float target = -0.73 + 0.16 * sin(elapsed * 0.11);
        float distance_angle = angle_gap(a, target);
        float arc = bell(distance_angle, 0.27) * bell(r - (1.42 + 0.035 * sin(distance_angle * 10.0 + elapsed * 0.35)), 0.012);
        float manual = 0.0;
        if (burst_power > 0.005) {
            float local_a = angle_gap(a, burst_direction);
            manual = bell(local_a, 0.34) * bell(r - (1.29 + 0.06 * sin(local_a * 7.0 + elapsed * 0.39)), 0.022) * burst_power;
        }
        float alpha = clamp((arc * pulse * 0.45 + manual * 0.60) * intensity * (1.0 + response_energy * 0.30), 0.0, 0.68);
        COLOR = vec4(cyan_color.rgb, alpha);
    }
}

shader_type canvas_item;
render_mode unshaded, blend_mix;
// Two slowly travelling, broken, circular liquid pressure waves.
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
uniform float response_energy : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cyan_color : source_color = vec4(0.55, 0.99, 0.97, 1.0);
uniform vec4 violet_color : source_color = vec4(0.65, 0.50, 0.95, 1.0);

float bell(float x, float w) { float v=x/w; return exp(-v*v); }
void fragment() {
    vec2 p = (UV - 0.5) * 4.10;
    float r = length(p);
    if (r < 1.0 || r > 1.97 || intensity < 0.001) { COLOR = vec4(0.0); }
    else {
        float a = atan(p.y, p.x);
        float t = elapsed;
        float total = 0.0;
        for (int i = 0; i < 2; i++) {
            float f = float(i);
            float phase = fract(t * 0.047 + f * 0.50);
            float center = 1.075 + 0.80 * phase + 0.025 * sin(a * 8.0 - t * 0.16 + f);
            float fade = sin(phase * 3.14159265); fade *= fade;
            float segmented = smoothstep(0.05, 0.43, sin(a * 4.0 + t * 0.08 + f * 1.7)) * 0.68 + 0.22;
            total += bell(r - center, 0.017 + phase * 0.014) * fade * segmented;
        }
        float alpha = clamp(total * (0.31 + response_energy * 0.24) * intensity, 0.0, 0.60);
        vec3 pigment = mix(cyan_color.rgb, violet_color.rgb, 0.25 + 0.25 * sin(a * 3.0));
        COLOR = vec4(pigment, alpha);
    }
}

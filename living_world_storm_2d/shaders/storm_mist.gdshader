shader_type canvas_item;
render_mode unshaded, blend_mix;
// Wide cloudy envelope. Coordinates are in units of the body's visible radius.
// The 768x768 storm sprite is scaled to 2.05 planet diameters by controller.
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.85;
uniform float response_energy : hint_range(0.0, 1.0) = 0.0;
uniform float detail_level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 cyan_color : source_color = vec4(0.23, 0.86, 0.87, 1.0);
uniform vec4 violet_color : source_color = vec4(0.56, 0.40, 0.92, 1.0);

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    vec2 p = (UV - 0.5) * 4.10;
    float r = length(p);
    if (r < 0.98 || r > 1.99 || intensity < 0.001) { COLOR = vec4(0.0); }
    else {
        float a = atan(p.y, p.x);
        float t = elapsed;
        float warp = noise2(p * 2.65 + vec2(t * 0.023, -t * 0.013));
        float weave = noise2(p * 5.45 - vec2(t * 0.011, t * 0.020));
        float fine = 0.5;
        if (detail_level > 0.5) { fine = noise2(p * 9.2 + vec2(-t * 0.013, t * 0.010)); }
        float spiral = sin(a * 3.0 - 4.5 * log(max(r, 0.8)) + 2.6 * warp - t * 0.09);
        float ring = 1.31 + 0.12 * sin(a * 4.0 + t * 0.11) + 0.12 * spiral;
        float band = exp(-pow((r - ring) / 0.36, 2.0));
        float outward = smoothstep(0.98, 1.18, r) * (1.0 - smoothstep(1.77, 2.0, r));
        float density = clamp(0.23 + 0.44 * warp + 0.23 * weave + 0.1 * fine, 0.0, 1.0);
        float alpha = outward * band * density * (0.25 + 0.15 * sin(a * 3.0 + t * 0.06)) * intensity;
        alpha *= 1.0 + response_energy * 0.42;
        vec3 color_mix = mix(violet_color.rgb, cyan_color.rgb, clamp(0.51 + 0.32 * spiral + 0.24 * warp, 0.0, 1.0));
        COLOR = vec4(color_mix, clamp(alpha, 0.0, 0.55));
    }
}

shader_type canvas_item;
render_mode unshaded, blend_mix;

// Deterministic non-circular shapes: long warped filaments, torn gas walls.
// TIME affects brightness by only a few percent; positions and silhouettes stay fixed.
uniform vec4 cloud_color : source_color = vec4(0.22, 0.57, 0.88, 1.0);
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.42;
uniform float cloud_seed = 0.0;
uniform float style = 0.0;
uniform float glow_strength = 0.55;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0,0.0)), f.x),
               mix(hash21(i + vec2(0.0,1.0)), hash21(i + vec2(1.0,1.0)), f.x), f.y);
}
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int k = 0; k < 4; k++) {
        value += amplitude * noise2(p);
        p = p * 2.12 + vec2(8.13, 4.91);
        amplitude *= 0.5;
    }
    return value;
}
void fragment() {
    vec2 uv = UV;
    vec2 p = (uv - vec2(0.5)) * 2.0;
    vec2 seedshift = vec2(cloud_seed * 0.37, cloud_seed * 0.61);
    // Strong anisotropy and static domain warping, like interstellar filaments.
    vec2 warp = vec2(fbm(p * vec2(1.85, 2.2) + seedshift),
                     fbm(p * vec2(3.2, 1.65) - seedshift));
    vec2 q = p + (warp - vec2(0.49)) * vec2(0.54, 0.65);
    float along = q.x;
    float fold = sin(along * 4.1 + cloud_seed) * 0.23
               + sin(along * 8.9 - cloud_seed * 1.7) * 0.075;
    float sideways = q.y - fold;
    float ridge_a = exp(-pow(abs(sideways - 0.18 * sin(along * 5.2 + 2.3)), 1.3) * 22.0);
    float ridge_b = exp(-pow(abs(sideways + 0.29 + 0.1 * sin(along * 7.0)), 1.2) * 37.0);
    float ridge_c = exp(-pow(abs(sideways - 0.34 + 0.09 * sin(along * 11.0)), 1.3) * 43.0);
    float torn = fbm(q * vec2(5.7, 3.6) + seedshift * 1.3);
    float fine = fbm(q * vec2(11.5, 9.7) - seedshift);
    float ridge = ridge_a * 0.73 + ridge_b * 0.43 + ridge_c * 0.34;
    float cloud = smoothstep(0.37, 0.78, torn + ridge * 0.36);
    float density = 0.0;
    if (style < 0.5) {
        // Long, broken supernova-like veil: strands with dark gaps.
        density = ridge * smoothstep(0.30, 0.70, torn) * (0.35 + 0.65 * fine);
    } else if (style < 1.5) {
        // A ragged gas wall with protrusions and ragged, uneven opacity.
        float wall = smoothstep(0.12, 0.66, ridge + torn * 0.45 - abs(sideways) * 0.26);
        density = wall * cloud * (0.18 + 0.82 * fine);
    } else {
        // Multiple disconnected ionized streamers, not a circle/ring.
        density = (ridge_a * 0.6 + ridge_b * 0.7 + ridge_c * 0.5)
                  * smoothstep(0.36, 0.73, fine * 0.6 + torn * 0.4);
    }
    // Only rectangular safety clipping; no circular radial alpha mask.
    float edge = smoothstep(0.0, 0.17, uv.x) * smoothstep(0.0, 0.17, uv.y)
               * (1.0 - smoothstep(0.83, 1.0, uv.x))
               * (1.0 - smoothstep(0.83, 1.0, uv.y));
    float shimmer = 0.97 + 0.03 * sin(TIME * 0.31 + cloud_seed * 2.6);
    float alpha = clamp(density * edge * cloud_opacity * shimmer, 0.0, 0.46);
    float highlights = clamp(fine * glow_strength * 0.40 + ridge * 0.16, 0.0, 0.42);
    vec3 color = mix(cloud_color.rgb * 0.52, cloud_color.rgb + vec3(0.16,0.18,0.22), highlights);
    COLOR = vec4(color, alpha);
}

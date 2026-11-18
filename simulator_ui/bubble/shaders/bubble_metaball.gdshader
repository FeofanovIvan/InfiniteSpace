shader_type canvas_item;
render_mode unshaded;

// A single procedural translucent body formed by smooth union of six circles.
// Units: pixel coordinates centered within a rectangular ColorRect.
uniform vec2 canvas_size = vec2(800.0, 650.0);
uniform float core_radius = 146.0;
uniform float time_offset = 0.0;
uniform float anim_time = 0.0;
uniform float travel_direction = 1.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.65;
uniform float dirty_level : hint_range(0.0, 1.0) = 0.0;

// x/y: satellite center relative to core, z: radius, w: connection softness.
uniform vec4 sat0 = vec4(-150.0, -75.0, 51.0, 46.0);
uniform vec4 sat1 = vec4(154.0, -90.0, 50.0, 46.0);
uniform vec4 sat2 = vec4(132.0, 124.0, 56.0, 46.0);
uniform vec4 sat3 = vec4(-139.0, 125.0, 47.0, 46.0);
uniform vec4 sat4 = vec4(30.0, -165.0, 25.0, 24.0);

float smooth_min(float a, float b, float softness) {
    float k = max(softness, 0.001);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - (h * h) * (0.25 * k);
}

float circle_sd(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}

float jelly_sd(vec2 p) {
    float wobble = 3.1 * sin(atan(p.y, p.x) * 5.0 + anim_time * 1.55 + time_offset);
    float sd = length(p) - (core_radius + wobble);
    sd = smooth_min(sd, circle_sd(p, sat0.xy, sat0.z), sat0.w);
    sd = smooth_min(sd, circle_sd(p, sat1.xy, sat1.z), sat1.w);
    sd = smooth_min(sd, circle_sd(p, sat2.xy, sat2.z), sat2.w);
    sd = smooth_min(sd, circle_sd(p, sat3.xy, sat3.z), sat3.w);
    sd = smooth_min(sd, circle_sd(p, sat4.xy, sat4.z), sat4.w);
    return sd;
}

void fragment() {
    vec2 p = UV * canvas_size - canvas_size * 0.5;
    float sd = jelly_sd(p);
    float aa = max(fwidth(sd), 1.1);
    float coverage = 1.0 - smoothstep(-aa, aa, sd);

    // Determine whichever lobe contributes most to the local surface.
    vec2 local = p / core_radius;
    float winner = circle_sd(p, vec2(0.0), core_radius);
    float d0 = circle_sd(p, sat0.xy, sat0.z);
    float d1 = circle_sd(p, sat1.xy, sat1.z);
    float d2 = circle_sd(p, sat2.xy, sat2.z);
    float d3 = circle_sd(p, sat3.xy, sat3.z);
    float d4 = circle_sd(p, sat4.xy, sat4.z);
    if (d0 < winner) { winner = d0; local = (p - sat0.xy) / sat0.z; }
    if (d1 < winner) { winner = d1; local = (p - sat1.xy) / sat1.z; }
    if (d2 < winner) { winner = d2; local = (p - sat2.xy) / sat2.z; }
    if (d3 < winner) { winner = d3; local = (p - sat3.xy) / sat3.z; }
    if (d4 < winner) { winner = d4; local = (p - sat4.xy) / sat4.z; }

    // Soft per-lobe 3D lighting (not a flat solid-color circle).
    float rr = dot(local, local);
    vec3 n = normalize(vec3(local * 0.72, sqrt(max(0.03, 1.0 - rr))));
    vec3 light_dir = normalize(vec3(-0.57, -0.75, 0.85));
    float diffuse = max(dot(n, light_dir), 0.0);
    float specular = pow(diffuse, 13.0);
    float reflected = pow(max(dot(n, normalize(vec3(0.36, 0.13, 0.93))), 0.0), 18.0);
    vec2 gleam_uv = (local - vec2(-0.47, -0.55)) * vec2(2.9, 7.0);
    float white_gleam = exp(-dot(gleam_uv, gleam_uv));
    float rim = 1.0 - smoothstep(-25.0, -1.0, sd);
    float thin_rim = exp(-abs(sd + 2.5) / 5.0);

    // Pearl colors and a restrained iridescent tint moving over time.
    vec3 lilac = vec3(0.71, 0.60, 0.96);
    vec3 turquoise = vec3(0.46, 0.89, 0.97);
    vec3 milky = vec3(0.92, 0.96, 1.00);
    float band = 0.5 + 0.5 * sin(5.6 * local.y - 3.1 * local.x + anim_time * 0.48 + time_offset + travel_direction * 0.14);
    vec3 color = mix(lilac, turquoise, band * 0.72 + 0.12);
    color = mix(color, milky, 0.16 + diffuse * 0.15);
    color += vec3(0.11, 0.15, 0.22) * specular;
    color += vec3(0.05, 0.13, 0.17) * reflected;
    color = mix(color, vec3(0.89, 0.95, 1.00), thin_rim * 0.82);
    color = mix(color, vec3(1.00, 1.00, 1.00), white_gleam * 0.70);
    color += vec3(0.08, 0.14, 0.25) * rim * glow_strength;
    color = mix(color, vec3(0.50, 0.48, 0.61), dirty_level * 0.60);

    // Decorative tiny pearlescent arcs inside satellite bubbles.
    float arcs = exp(-abs(d0 + 7.0) / 5.0)
               + exp(-abs(d1 + 7.0) / 5.0)
               + exp(-abs(d2 + 7.0) / 5.0)
               + exp(-abs(d3 + 7.0) / 5.0)
               + exp(-abs(d4 + 7.0) / 5.0);
    color = mix(color, milky, min(arcs * 0.15, 0.25));

    // Alpha remains transparent outside all bubbles; no image background.
    float material_alpha = mix(0.76, 0.95, diffuse * 0.42 + rim * 0.33);
    COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), coverage * material_alpha);
}

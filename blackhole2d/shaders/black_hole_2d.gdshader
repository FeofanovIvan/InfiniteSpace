shader_type canvas_item;
render_mode unshaded;

// Independent, self-contained 2D black hole shader. Draw AFTER the star/background layers.
// Screen-reading is used to bend the background; this is an artistic lens approximation,
// NOT numerical general-relativistic ray tracing. No externally downloaded textures.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float animation_time = 0.0;
uniform float shadow_radius : hint_range(0.075, 0.18) = 0.122;
uniform float disk_tilt : hint_range(0.18, 0.65) = 0.29;
uniform float disk_outer_radius : hint_range(0.30, 0.48) = 0.438;
uniform float rotation_speed : hint_range(0.0, 3.0) = 0.30;
uniform float lensing_strength : hint_range(0.0, 1.0) = 0.60;
uniform float disk_brightness : hint_range(0.15, 2.0) = 1.0;
uniform float beaming_strength : hint_range(0.0, 1.0) = 0.78;
uniform float warm_palette : hint_range(0.0, 1.0) = 1.0;
uniform float sprite_size_pixels = 400.0;
uniform bool show_disk = true;
uniform bool show_lensing = true;

float gauss(float x, float w) {
    float a = x / max(w, 0.0001);
    return exp(-a * a);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    vec2 p = UV - vec2(0.5);
    float r = length(p);
    float t = animation_time * rotation_speed;
    vec2 radial_dir = p / max(r, 0.0001);

    // Screen background bending around the silhouette. Capture happens before this sprite.
    vec2 source_uv = SCREEN_UV;
    if (show_lensing && (r > shadow_radius) && (r < 0.48)) {
        float falloff = 1.0 - smoothstep(shadow_radius, 0.465, r);
        float outside_shadow = smoothstep(shadow_radius, shadow_radius + 0.027, r);
        float shift_px = lensing_strength * 30.0 * falloff * outside_shadow;
        source_uv -= radial_dir * shift_px * SCREEN_PIXEL_SIZE;
    }
    vec3 bg = texture(screen_texture, clamp(source_uv, vec2(0.001), vec2(0.999))).rgb;
    vec3 result = bg;

    // Thin tilted disk of orbiting plasma, projected into the 2D screen.
    vec2 disc_p = vec2(p.x, (p.y + 0.004) / max(disk_tilt, 0.1));
    float disc_r = length(disc_p);
    float ang = atan(disc_p.y, disc_p.x);
    float ring_mask = smoothstep(0.163, 0.186, disc_r) *
                      (1.0 - smoothstep(disk_outer_radius - 0.045, disk_outer_radius, disc_r));

    // Spatially structured turbulent gas, differential rotation: inner regions orbit faster.
    float phase = ang * 11.0 - t * (1.3 / (0.22 + disc_r));
    float n = noise2(vec2(ang * 6.0 + t * 1.0, disc_r * 39.0 - t * 0.42));
    float band = 0.66 + 0.14 * sin(disc_r * 123.0 + sin(phase) * 1.9)
                + 0.10 * sin(disc_r * 230.0 - phase * 0.33)
                + 0.20 * (n - 0.5);
    band = clamp(band, 0.13, 1.10);
    float temperature = 1.0 - smoothstep(0.17, disk_outer_radius + 0.035, disc_r);

    float toward_side = 1.0 - smoothstep(-0.37, 0.37, p.x);
    float beam = mix(1.0, mix(0.59, 1.56, toward_side), beaming_strength);
    vec3 hot = mix(vec3(1.0, 0.24, 0.028), vec3(1.0, 0.78, 0.31), pow(temperature, 1.2));
    vec3 cool = mix(vec3(0.15, 0.40, 0.95), vec3(0.78, 0.88, 1.0), temperature);
    vec3 disk_color = mix(cool, hot, warm_palette);
    float main_plasma = ring_mask * band * beam;
    // Broad, faint halo around disk; prevents the gas from appearing as a rigid ring.
    float halo = gauss(disc_r - 0.27, 0.18) * 0.10 *
        smoothstep(0.16, 0.23, disc_r) * (1.0 - smoothstep(0.43, 0.51, disc_r));

    // Lensed upper image of the far side of the disk, distorted into an arched ribbon.
    float sx = clamp(abs(p.x) / 0.435, 0.0, 1.0);
    float arch_y = -0.083 - 0.177 * pow(max(0.0, 1.0 - sx * sx), 0.75);
    float arch_visibility = 1.0 - smoothstep(0.36, 0.45, abs(p.x));
    float advected = p.x * 68.0 + t * 2.0 + 0.5 * sin(p.x * 45.0 - t * 1.3);
    float arch_bands = 0.66 + 0.22 * sin(advected) +
                       0.12 * sin(p.x * 138.0 + t * 0.7);
    float upper_arc = (gauss(p.y - arch_y, 0.029) * 0.70 +
                      gauss(p.y - (arch_y + 0.023), 0.009) * 0.43) * arch_visibility;
    upper_arc *= max(0.25, arch_bands) * mix(0.72, 1.43, toward_side);
    // Dim secondary image of the underside of the far side of the disk.
    float bx = clamp(abs(p.x) / 0.25, 0.0, 1.0);
    float bottom_y = 0.108 + 0.042 * sqrt(max(0.0, 1.0 - bx * bx));
    float lower_arc = gauss(p.y - bottom_y, 0.017) *
                       (1.0 - smoothstep(0.19, 0.255, abs(p.x))) * 0.27;

    if (show_disk) {
        result += disk_brightness * disk_color * (main_plasma + halo);
        vec3 arch_color = mix(vec3(0.25, 0.61, 1.0), vec3(1.0, 0.39, 0.075), warm_palette);
        result += disk_brightness * arch_color * upper_arc;
        result += disk_brightness * arch_color * lower_arc;
    }

    // The opaque shadow hides anything behind the central silhouette.
    float silhouette = 1.0 - smoothstep(shadow_radius - 0.0025,
                                         shadow_radius + 0.0025, r);
    result = mix(result, vec3(0.00045, 0.0006, 0.0017), silhouette);

    if (show_disk) {
        // Fainter narrow photon-ring approximation. Not an actual ray-traced photon ring.
        float photon = gauss(r - (shadow_radius + 0.006), 0.0036) * 0.73 +
                       gauss(r - (shadow_radius + 0.015), 0.008) * 0.105;
        vec3 photon_color = mix(vec3(0.28, 0.65, 1.0), vec3(1.0, 0.74, 0.31), warm_palette);
        result += disk_brightness * photon_color * photon;
    }
    COLOR = vec4(clamp(result, 0.0, 1.0), 1.0);
}

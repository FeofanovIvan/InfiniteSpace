shader_type canvas_item;
render_mode blend_mix, unshaded;

// Infinity Space / M31 magnetic liquid life-form.
// Entire geometry is one SDF union. No sprites, orbits or separate droplets.

uniform float phase_time = 0.0;
uniform float morph : hint_range(0.0, 1.0) = 0.0;
uniform float agitation : hint_range(0.0, 1.0) = 0.22;
uniform float field_power : hint_range(0.0, 1.0) = 0.0;
uniform vec2 field_point = vec2(0.35, -0.15);
uniform vec4 metal_tint : source_color = vec4(0.76, 0.86, 1.0, 1.0);
uniform vec4 warm_tint : source_color = vec4(1.0, 0.41, 0.08, 1.0);

vec2 rotate2d(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float smooth_union(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec2 segment_closest(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b - a;
    return a + ba * clamp(dot(p - a, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
}

float ellipse_distance(vec2 p, vec2 radii) {
    // Approximate signed distance, suitable for smooth implicit shape blending.
    float k0 = length(p / radii);
    float k1 = length(p / (radii * radii));
    if (k0 < 0.0001) {
        return -min(radii.x, radii.y);
    }
    return k0 * (k0 - 1.0) / max(k1, 0.001);
}

void fragment() {
    vec2 pixel = (UV - vec2(0.5)) * 2.0;
    float t = phase_time;

    // A touch/magnetic field merely pulls the mass. It never splits the organism.
    vec2 toward = field_point - pixel;
    float pull = field_power * exp(-dot(toward, toward) * 2.5);
    pixel -= 0.10 * toward * pull;

    float inclination = -0.39 + 0.055 * sin(t * 0.25);
    vec2 p = rotate2d(pixel, -inclination);

    // A gently living, imperfect toroidal centre-line.
    float a = atan(p.y / 0.72, p.x / 0.54);
    float disturbance = (0.012 + 0.025 * agitation) * sin(3.0 * a + t * 0.71)
                      + 0.010 * sin(5.0 * a - t * 0.48)
                      + 0.007 * sin(8.0 * a + t * 1.07);
    float protrusion = 0.12 * agitation * pow(max(0.0, sin(4.0 * a - t * 0.64)), 12.0);
    float radius_ratio = 1.0 + disturbance + protrusion;
    vec2 path = vec2(0.54 * cos(a), 0.72 * sin(a)) * radius_ratio;
    float tube_radius = 0.167 + 0.016 * sin(2.0 * a + t * 0.51)
                      + 0.013 * sin(7.0 * a - t * 1.11);
    float tube_length = length(p - path);
    float ring_d = tube_length - tube_radius;

    // Connected amber heart, not a floating sphere: a thin metallic neck
    // is merged into both heart and torus using the same implicit body.
    vec2 heart = vec2(-0.025 + 0.025 * sin(t * 0.53), 0.014 * cos(t * 0.73));
    float heart_radius = 0.143 + 0.008 * sin(t * 1.17);
    float heart_length = length(p - heart);
    float heart_d = heart_length - heart_radius;

    vec2 neck_a = heart + vec2(0.09, 0.00);
    vec2 neck_b = vec2(0.465, 0.012 * sin(t * 0.40));
    vec2 closest = segment_closest(p, neck_a, neck_b);
    float neck_radius = 0.050;
    float neck_length = length(p - closest);
    float neck_d = neck_length - neck_radius;

    float one_ring_body = smooth_union(ring_d, neck_d, 0.076);
    one_ring_body = smooth_union(one_ring_body, heart_d, 0.073);

    // Closing the hole produces a compact amoeba-like droplet, continuously.
    vec2 droplet_radii = vec2(0.64, 0.81) * (1.0 + 0.025 * sin(t * 0.37));
    float blob_d = ellipse_distance(p, droplet_radii);
    blob_d += 0.026 * sin(5.0 * a + t * 0.80)
            + 0.028 * agitation * sin(7.0 * a - t * 0.63);
    float d = mix(one_ring_body, blob_d, smoothstep(0.0, 1.0, morph));

    // Independent pixels outside the SDF are fully transparent; only one entity.
    float edge = max(fwidth(d), 0.0015) * 1.15;
    float opacity = 1.0 - smoothstep(-edge, edge, d);
    if (opacity < 0.004) {
        discard;
    }

    // Approximate normal of a rounded tube, heart, neck or full droplet.
    vec2 offset = p - path;
    float cross_radius = tube_radius;
    if (heart_d < ring_d && heart_d < neck_d) {
        offset = p - heart;
        cross_radius = heart_radius;
    } else if (neck_d < ring_d && neck_d < heart_d) {
        offset = p - closest;
        cross_radius = neck_radius;
    }
    vec2 out_dir = normalize(offset + vec2(0.00001));
    float cross_fraction = clamp(length(offset) / max(cross_radius, 0.01), 0.0, 1.0);
    vec3 ring_normal = normalize(vec3(out_dir * cross_fraction,
                                      1.35 * sqrt(max(0.0, 1.0 - cross_fraction * cross_fraction))));

    vec2 ellipse_normal = normalize(p / (droplet_radii * droplet_radii) + vec2(0.00001));
    float blob_fraction = clamp(length(p / droplet_radii), 0.0, 1.0);
    vec3 blob_normal = normalize(vec3(ellipse_normal * blob_fraction,
                                      1.35 * sqrt(max(0.0, 1.0 - blob_fraction * blob_fraction))));
    vec3 n = normalize(mix(ring_normal, blob_normal, smoothstep(0.18, 0.48, morph)));
    n.xy = rotate2d(n.xy, inclination);
    vec3 reflected = reflect(vec3(0.0, 0.0, -1.0), n);

    // Studio-like blue steel reflections + two scrolling amber light sources.
    float side = 0.48 + 0.48 * reflected.y;
    float cold_band = pow(max(0.0, cos(3.9 * reflected.x - 1.5 * reflected.y + 0.35)), 16.0);
    float thin_band = pow(max(0.0, cos(6.2 * reflected.y + 2.0 * reflected.x - 0.45)), 24.0);
    float dark_band = 0.5 + 0.5 * cos(12.0 * reflected.x + 5.0 * reflected.y + 0.72);

    vec3 metal = mix(vec3(0.012, 0.020, 0.038), vec3(0.23, 0.32, 0.45), side * 0.54 + dark_band * 0.15);
    metal += vec3(0.70, 0.82, 1.0) * cold_band * 0.82;
    metal += vec3(0.92, 0.96, 1.0) * thin_band * 0.37;

    float amber_side = pow(max(dot(n, normalize(vec3(0.77, 0.18, 0.57))), 0.0), 4.0);
    float amber_strip = pow(max(0.0, sin(5.1 * reflected.x + 2.2 * reflected.y + t * 0.10)), 12.0);
    float amber_reflection = (0.42 * amber_side + 0.33 * amber_strip);
    metal += warm_tint.rgb * amber_reflection;

    float edge_shine = pow(1.0 - max(n.z, 0.0), 4.0);
    metal += metal_tint.rgb * (0.09 * edge_shine);
    metal *= mix(vec3(1.0), metal_tint.rgb, 0.24);

    // The heart is gold, but is still part of exactly the same connected body.
    float gold_mask = (1.0 - smoothstep(heart_radius * 0.45, heart_radius * 1.18, heart_length))
                    * (1.0 - smoothstep(0.42, 0.84, morph));
    vec3 gold = vec3(0.28, 0.065, 0.008) + warm_tint.rgb * (0.43 + 0.46 * pow(max(n.z, 0.0), 2.0));
    gold += vec3(1.0, 0.83, 0.36) * pow(max(dot(n, normalize(vec3(-0.43, -0.55, 0.72))), 0.0), 18.0);
    metal = mix(metal, gold, gold_mask * 0.95);

    COLOR = vec4(clamp(metal, vec3(0.0), vec3(1.0)), opacity);
}

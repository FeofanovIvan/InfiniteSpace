shader_type canvas_item;
render_mode unshaded, blend_mix;

// Soft viscous eruptions: three staggered autonomous arches plus an interaction pulse.
// Everything is rendered inside the original 768px transparent texture rect.
uniform float elapsed = 0.0;
uniform float activity : hint_range(0.0, 2.0) = 0.85;
uniform float flare_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float flare_rate : hint_range(0.1, 2.5) = 1.0;
uniform float burst_power : hint_range(0.0, 2.0) = 0.0;
uniform float burst_angle = -1.0;
uniform float detail_level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 core_color : source_color = vec4(0.16, 0.77, 0.82, 1.0);
uniform vec4 glint_color : source_color = vec4(0.78, 0.89, 1.0, 1.0);

float bell(float x, float width) {
    float z = x / max(width, 0.001);
    return exp(-z * z);
}

float angular_distance(float a, float b) {
    return atan(sin(a - b), cos(a - b));
}

// Result: x=thick liquid band, y=small suspended globs, z=soft surrounding glow.
vec3 arch(vec2 p, float a0, float age, float power, float width, float variation) {
    float r = length(p);
    float a = atan(p.y, p.x);
    float x = angular_distance(a, a0) / width;
    float fade = smoothstep(0.02, 0.17, age) * (1.0 - smoothstep(0.69, 0.99, age));
    float curvature = max(0.0, 1.0 - x * x);
    float arc_height = min(0.19, (0.095 + 0.084 * sin(age * 3.14159265)) * power * fade);
    float r_arc = 0.750 + arc_height * pow(curvature, 1.18);
    float taper = 1.0 - smoothstep(0.75, 1.08, abs(x));
    // Two graceful overlapping viscous filaments, not sharp flame tongues.
    float band = bell(r - r_arc, 0.010 + 0.010 * power) * taper * fade;
    float inner_band = bell(r - (r_arc - 0.021), 0.024) * taper * fade * 0.52;
    float halo = bell(r - r_arc, 0.051 + 0.018 * power) * taper * fade;
    float beads = 0.0;
    if (detail_level > 0.5) {
        for (int j = 0; j < 3; j++) {
            float fj = float(j);
            float aj = a0 + (fj - 1.0) * 0.25 * width + 0.09 * sin(age * 5.4 + variation + fj);
            float launch = max(0.0, sin(age * 3.14159265));
            float height = 0.755 + arc_height * (0.65 + 0.2 * fj) + launch * (0.013 + 0.007 * fj);
            vec2 bead_at = vec2(cos(aj), sin(aj)) * height;
            beads += bell(length(p - bead_at), (0.009 + fj * 0.003) * (0.8 + 0.2 * power)) * fade;
        }
    }
    return vec3(band + inner_band, beads, halo);
}

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float r = length(p);
    if (r > 0.98 || r < 0.72 || flare_intensity <= 0.001) {
        COLOR = vec4(0.0);
    } else {
        vec3 glow = vec3(0.0);
        for (int i = 0; i < 3; i++) {
            float index = float(i);
            float age = fract(elapsed * (0.055 + 0.030 * flare_rate) + index * 0.341);
            float direction = -2.35 + 2.25 * index + 0.16 * sin(elapsed * 0.055 + index * 1.9);
            float energy = flare_intensity * activity * (0.77 + index * 0.12);
            glow += arch(p, direction, age, energy, 0.23 + index * 0.042, index);
        }
        // Extra pulse, manually launched by player touch or later by the dialogue system.
        if (burst_power > 0.001) {
            float age = clamp(1.0 - burst_power * 0.72, 0.0, 1.0);
            glow += arch(p, burst_angle, age, burst_power * flare_intensity * 1.52, 0.36, 3.0);
        }
        float filament = clamp(glow.x, 0.0, 1.0);
        float drops = clamp(glow.y, 0.0, 1.0);
        float halo = clamp(glow.z, 0.0, 1.0);
        vec3 pigment = mix(core_color.rgb, glint_color.rgb, clamp(0.38 * filament + 0.88 * drops, 0.0, 0.83));
        float alpha = clamp(filament * 0.88 + drops * 0.91 + halo * 0.14, 0.0, 0.96);
        COLOR = vec4(pigment, alpha);
    }
}

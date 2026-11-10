shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// MIKA phase creature v3. One connected UV-surface, warped on the GPU.
// No independent bubbles, particles, detachable tentacles or textures.
const float PI_V = 3.141592653589793;
const float TAU_V = 6.283185307179586;

uniform float morph_clock = 0.0;
uniform float flow_speed : hint_range(0.1, 2.5) = 0.85;
uniform float spiral_strength : hint_range(0.0, 1.0) = 0.82;
uniform float lobe_strength : hint_range(0.0, 1.3) = 0.92;
uniform float gravity_weight : hint_range(0.5, 1.5) = 1.0;
uniform float speech_level : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.9;
uniform float glass_opacity : hint_range(0.55, 0.98) = 0.84;
uniform float color_shift : hint_range(0.0, 6.28) = 0.0;

varying vec3 body_p;
varying vec2 body_uv;
varying float bulge_mask;

float g2(float x, float width) {
    float z = x / max(width, 0.001);
    return exp(-z * z);
}

float a_dist(float a, float b) {
    float d = a - b;
    return atan(sin(d), cos(d));
}

float pulse(float v) {
    float c = fract(v);
    return smoothstep(0.02, 0.22, c) * (1.0 - smoothstep(0.61, 0.94, c));
}

// p.xyz is a volumetric 3D point in object space; always closed at both tips.
vec4 shape(float h, float angle) {
    float t = morph_clock * flow_speed;
    float s = sin(PI_V * clamp(h, 0.0, 1.0));
    float r = pow(max(s, 0.0), 0.56) * (1.96 * pow(1.0 - h, 1.73 * gravity_weight) + 0.09);

    // Small organic asymmetry, never a symmetric star/flat top view.
    r *= 1.0 + 0.055 * sin(3.0 * angle + h * 7.0 - t * 0.53)
             + 0.025 * sin(5.0 * angle - h * 12.0 + t * 0.37);

    // Three independently born/melting spiral tongues, all fused into the same surface.
    float c0 = 0.72 + 6.4 * h + 0.22 * sin(t * 0.36);
    float c1 = 3.54 + 5.25 * h - 0.25 * sin(t * 0.43);
    float c2 = 5.15 + 7.2 * h + 0.19 * cos(t * 0.37);
    float e0 = pulse(t * 0.115 + 0.17);
    float e1 = pulse(t * 0.093 + 0.57);
    float e2 = pulse(t * 0.078 + 0.88);

    // Neighbouring ridges approach and temporarily become one flowing protrusion.
    float union_phase = speech_level * smoothstep(0.37, 0.87, 0.5 + 0.5 * sin(t * 0.76));
    c1 += a_dist(c0, c1) * union_phase * 0.88;

    float k = 0.32 + 1.09 * speech_level;
    float b0 = g2(a_dist(angle, c0), 0.43) * g2(h - 0.62, 0.23) * e0;
    float b1 = g2(a_dist(angle, c1), 0.42) * g2(h - 0.73, 0.20) * e1;
    float b2 = g2(a_dist(angle, c2), 0.42) * g2(h - 0.83, 0.15) * e2;
    float ribbons = k * (1.20*b0 + 1.06*b1 + 0.82*b2);

    // Always-visible faint spiral groove, so the creature remains spiral in idle.
    float groove = sin(angle * 2.0 - h * (9.0 + 3.0*spiral_strength) + t * 0.44);
    float tip_fade = pow(max(s, 0.0), 0.42);
    r += 0.11 * spiral_strength * g2(h - 0.58, 0.38) * groove * tip_fade;

    // Dense internal droplets pressure the continuous surface from INSIDE.
    float bubbles = speech_level * (0.27 * g2(a_dist(angle, t*0.58 + 2.1*h), 0.47) * g2(h - (0.40 + 0.07*sin(t*.6)), 0.095)
                 + 0.18 * g2(a_dist(angle, -t*0.35 - 3.5*h), 0.36) * g2(h - 0.72, 0.10));
    r += lobe_strength * (ribbons + bubbles) * tip_fade;
    r = max(0.0, r);

    float bend = pow(h, 1.35);
    float cx = bend * (0.14 * sin(2.45*h - t*0.27) + 0.11 * sin(t*0.14));
    float cz = bend * (0.12 * cos(3.5*h + t*0.22));
    vec3 p = vec3(cx + r*cos(angle), 5.1*h, cz + r*sin(angle));
    return vec4(p, clamp(ribbons + bubbles, 0.0, 1.0));
}

void vertex() {
    float h = UV.y;
    float a = UV.x * TAU_V;
    vec4 p = shape(h, a);
    VERTEX = p.xyz;
    // Recompute true 3D normals after every GPU deformation.
    vec3 v_h = shape(clamp(h + 0.0016, 0.0, 1.0), a).xyz - shape(clamp(h - 0.0016, 0.0, 1.0), a).xyz;
    vec3 v_a = shape(h, a + 0.0035).xyz - shape(h, a - 0.0035).xyz;
    if (h < 0.001) {
        NORMAL = vec3(0.0, -1.0, 0.0);
    } else if (h > 0.999) {
        NORMAL = vec3(0.0, 1.0, 0.0);
    } else {
        NORMAL = normalize(cross(v_h, v_a));
    }
    body_p = p.xyz;
    body_uv = UV;
    bulge_mask = p.w;
}

void fragment() {
    float h = body_uv.y;
    float theta = atan(body_p.z, body_p.x);
    float t = morph_clock * flow_speed;
    float helix = theta * 2.0 - h * 14.0 + t * 1.08 + color_shift;
    float spiral = pow(0.5 + 0.5*cos(helix), 7.0);
    float fine = pow(0.5 + 0.5*sin(helix*1.6 + h*6.0 - t*0.33), 6.0);
    float flow = 0.5 + 0.5*sin(h*18.0 - t*1.62 + theta*3.0 + 0.6*sin(helix));
    float face = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float rim = pow(1.0 - face, 2.2);

    vec3 dark = vec3(0.018, 0.095, 0.25);
    vec3 cyan = vec3(0.055, 0.79, 0.86);
    vec3 purple = vec3(0.52, 0.24, 0.9);
    vec3 gel = mix(dark, cyan, 0.38 + 0.27*flow);
    gel = mix(gel, purple, 0.13 + 0.31*fine);
    gel = mix(gel, cyan*1.22, (0.24 + 0.62*spiral_strength)*spiral*0.5);

    ALBEDO = gel;
    METALLIC = 0.0;
    ROUGHNESS = 0.12;
    SPECULAR = 0.91;
    EMISSION = glow_strength * (
        cyan * (0.075 + spiral * 0.31 * spiral_strength + bulge_mask*0.19) +
        purple * (0.050 + fine*0.22) +
        vec3(0.12, 0.31, 0.44) * rim * 0.55
    ) * (1.0 + 0.42 * speech_level);
    ALPHA = clamp(glass_opacity - 0.08*face + 0.14*rim + 0.05*spiral, 0.63, 0.99);
}

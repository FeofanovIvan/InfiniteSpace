shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;
// MIKA / Phase Liquid v4 | One watertight 3D body with fast travelling geometry ripples.
// No meshes for floating bubbles. All bulges and fins are deformations of one surface.
const float PI_V = 3.14159265359;
const float TAU_V = 6.28318530718;

uniform float morph_clock = 0.0;
uniform float flow_speed : hint_range(0.2, 3.0) = 1.35;
uniform float spiral_strength : hint_range(0.0, 1.6) = 1.08;
uniform float lobe_strength : hint_range(0.0, 1.8) = 1.24;
uniform float gravity_weight : hint_range(0.6, 1.5) = 1.03;
uniform float speech_level : hint_range(0.0, 1.0) = 0.1;
uniform float glow_strength : hint_range(0.0, 2.5) = 1.18;
uniform float glass_opacity : hint_range(0.75, 1.0) = 0.96;
uniform float color_shift : hint_range(0.0, 6.28) = 0.0;
uniform float ripple_strength : hint_range(0.0, 1.3) = 0.61;
uniform float bubble_strength : hint_range(0.0, 1.4) = 0.64;
uniform float morph_strength : hint_range(0.0, 2.0) = 1.18;

varying vec3 body_position;
varying vec2 body_uv;
varying float body_bulge;
varying float body_ripple;

float gauss(float d, float w) {
    float q = d / max(w, 0.0001);
    return exp(-q*q);
}
float ang_dist(float a, float b) {
    return atan(sin(a-b), cos(a-b));
}
float turn_on(float x) { return smoothstep(0.13, 0.86, x); }

// Compute the SAME surface in Godot as in CPU preview_geometry_v4.py.
// Outputs shape.xyz and the envelope of active bulges in w.
vec4 surface(float h, float a) {
    float t = morph_clock * flow_speed;
    float H = clamp(h, 0.0, 1.0);
    float ss = max(0.0, sin(PI_V * H));
    float tip = pow(ss, 0.62);
    float r = tip * (1.84 * pow(1.0 - H, 1.58 * gravity_weight) + 0.12);

    // Wavy vertical asymmetry and breathing, with a clear heavy base.
    r *= 1.0 + 0.070*sin(3.0*a + 7.4*H - 0.81*t)
             + 0.034*sin(5.0*a - 11.5*H + 0.62*t);
    r *= 1.0 + 0.055*sin(t*1.27 - H*5.6);

    // Three rounded helix-shaped tongues. Their birth/merge cycles are 2-4s,
    // instead of v3's slow 9-13s cycles.
    float c0 = 0.35 + 6.6*H + 0.31*sin(t*0.69);
    float c1 = 2.87 + 5.5*H - 0.27*sin(t*0.83);
    float c2 = 4.90 + 7.3*H + 0.22*cos(t*0.77);
    float b0 = 0.56 + 0.44*sin(t*2.00 + 0.40);
    float b1 = 0.56 + 0.44*sin(t*1.75 + 2.80);
    float b2 = 0.56 + 0.44*sin(t*2.23 + 4.20);
    float merge = speech_level * turn_on(0.5 + 0.5*sin(t*1.6));
    c1 += ang_dist(c0, c1) * merge * 0.72;
    float g0 = gauss(ang_dist(a, c0), 0.50) * gauss(H - 0.57, 0.25) * b0;
    float g1 = gauss(ang_dist(a, c1), 0.53) * gauss(H - 0.70, 0.23) * b1;
    float g2 = gauss(ang_dist(a, c2), 0.48) * gauss(H - 0.81, 0.16) * b2;
    float lobes = (0.34 + 0.94*speech_level)*(1.22*g0 + 1.05*g1 + 0.85*g2);
    r += morph_strength*lobe_strength * lobes * pow(ss, 0.40);

    // Real geometry ripples: travelling both upward and around the body.
    float upwave = sin(14.5*H - 2.0*a - t*3.15);
    float crosswave = sin(24.0*H + 3.0*a + t*2.32);
    float helix = sin(2.0*a - 11.8*H + t*1.30);
    float local = gauss(H - 0.57, 0.37)*pow(ss, 0.5);
    float waves = (0.125*upwave + 0.060*crosswave + 0.065*helix*spiral_strength);
    r += ripple_strength * (0.67 + 0.48*speech_level) * local * waves * morph_strength;

    // Bubble-shaped blisters remain attached to the surface. Two independent
    // moving pressure points; none can detach or float away.
    float q0 = 0.43 + 0.12*sin(t*1.13 + 1.10);
    float q1 = 0.68 + 0.08*sin(t*1.37 + 2.7);
    float p0 = gauss(ang_dist(a, t*1.10 + 2.3*H), 0.57) * gauss(H-q0, 0.105);
    float p1 = gauss(ang_dist(a, -t*1.16 + 3.2*H + 2.1), 0.52) * gauss(H-q1, 0.095);
    float bubble = (0.25*p0 + 0.19*p1) * (0.35 + 0.80*speech_level);
    r += bubble_strength * bubble * pow(ss, 0.35) * morph_strength;
    r = max(0.0, r);

    // Moving S-curve spine: the centre of mass stays low. Avoid lateral tilt.
    float bend = pow(H, 1.45);
    float cx = bend*(0.17*sin(2.9*H - t*0.64) + 0.15*sin(t*0.36));
    float cz = bend*(0.16*cos(3.0*H + t*0.53));
    vec3 p = vec3(cx + r*cos(a), 5.1*H, cz + r*sin(a));
    return vec4(p, clamp(lobes+bubble,0.0,1.0));
}

void vertex() {
    float h = UV.y;
    float a = UV.x*TAU_V;
    vec4 p = surface(h,a);
    VERTEX = p.xyz;
    // Geometry-derived normals make the actual ripples visible under lights,
    // independent of emission/texture (important in GL Compatibility).
    vec3 dh = surface(clamp(h+0.0015,0.0,1.0),a).xyz
            - surface(clamp(h-0.0015,0.0,1.0),a).xyz;
    vec3 da = surface(h,a+0.0040).xyz - surface(h,a-0.0040).xyz;
    if (h <= 0.00001) {
        NORMAL = vec3(0.0,-1.0,0.0);
    } else if (h >= 0.99999) {
        NORMAL = vec3(0.0,1.0,0.0);
    } else {
        NORMAL = normalize(cross(dh,da));
    }
    body_position = p.xyz;
    body_uv = UV;
    body_bulge = p.w;
    body_ripple = 0.5 + 0.5*sin(14.5*h - 2.0*a - morph_clock*flow_speed*3.15);
}

void fragment() {
    float t = morph_clock*flow_speed;
    float h = body_uv.y;
    float theta = body_uv.x*TAU_V;
    float spiral_phase = 2.0*theta - 14.2*h + t*1.72 + color_shift;
    float spiral = pow(0.5+0.5*cos(spiral_phase),6.0);
    float vein = pow(0.5+0.5*sin(spiral_phase*1.3 + 6.5*h - 0.75*t),5.0);
    float liquid_flow = 0.5+0.5*sin(20.0*h - 2.6*t + 3.0*theta + 0.54*sin(spiral_phase));
    float nface = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float rim = pow(1.0-nface,1.65);
    float pulse_glow = 0.82 + 0.18*sin(t*2.45 + h*9.0);
    // Stable camera-space pearly key-light, visible even without reflection probes.
    float pearl = pow(max(dot(normalize(NORMAL), normalize(vec3(-0.38,0.72,0.58))),0.0),26.0);
    float soft_pearl = pow(max(dot(normalize(NORMAL), normalize(vec3(0.70,0.18,0.69))),0.0),12.0);

    vec3 dark = vec3(0.020,0.080,0.190);
    vec3 cyan = vec3(0.048,0.88,0.98);
    vec3 violet = vec3(0.58,0.19,0.97);
    vec3 deep_blue = vec3(0.04,0.25,0.65);
    vec3 gel = mix(dark,deep_blue,0.25+0.19*liquid_flow);
    gel = mix(gel,cyan,0.31+0.30*body_ripple);
    gel = mix(gel,violet,0.13+0.37*vein);
    gel = mix(gel,cyan,clamp(spiral*(0.25+0.35*spiral_strength),0.0,0.83));
    gel += (cyan*0.08 + violet*0.09)*body_bulge;

    ALBEDO = gel;
    METALLIC = 0.0;
    ROUGHNESS = 0.11;
    SPECULAR = 0.92;
    EMISSION = glow_strength*pulse_glow*(
        cyan*(0.085 + 0.30*spiral*spiral_strength + 0.19*body_ripple*ripple_strength)
        + violet*(0.046 + 0.22*vein)
        + vec3(0.07,0.18,0.29)*rim*0.66
        + cyan*body_bulge*0.15
        + vec3(0.44,0.65,0.78)*pearl*0.21
        + violet*soft_pearl*0.12
    )*(1.0 + 0.32*speech_level);
    // Almost opaque gel keeps color/volume across GL Compatibility and when
    // composited over a 2D backdrop; it is NOT a glass refraction simulation.
    ALPHA = clamp(glass_opacity + 0.055*rim, 0.85, 0.999);
}

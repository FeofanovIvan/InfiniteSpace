shader_type canvas_item;
render_mode unshaded, blend_mix;

// Living being rather than a watery planet. One full-screen quad is the entire body.
uniform sampler2D organic_noise : repeat_enable, filter_linear_mipmap;
uniform vec4 shadow_color : source_color = vec4(0.055, 0.020, 0.155, 1.0);
uniform vec4 middle_color : source_color = vec4(0.19, 0.15, 0.43, 1.0);
uniform vec4 liquid_color : source_color = vec4(0.16, 0.77, 0.82, 1.0);
uniform vec4 pearl_color : source_color = vec4(0.75, 0.87, 0.96, 1.0);
uniform float elapsed = 0.0;
uniform float activity : hint_range(0.0, 2.0) = 0.8;
uniform float viscosity : hint_range(0.0, 2.0) = 0.92;
uniform float response_power : hint_range(0.0, 1.0) = 0.0;
uniform vec2 response_origin = vec2(0.2, -0.1);
uniform float detail_level : hint_range(0.0, 1.0) = 1.0;
uniform float illumination : hint_range(0.0, 2.0) = 1.0;

float radial_radius(vec2 p, float t) {
    float a = atan(p.y, p.x);
    float w1 = sin(a * 5.0 + t * 0.54 + sin(a * 3.0 - t * 0.27)) * 0.010;
    float w2 = sin(a * 8.0 - t * 0.38 + sin(a * 2.0 + t * 0.13)) * 0.005;
    float w3 = sin(a * 13.0 + t * 0.16) * 0.003;
    float slow_breath = 0.008 * sin(t * 0.67) + 0.006 * sin(t * 0.31);
    // Only a gentle deformation of the visible limb; do not morph into a flat blob.
    float hit = pow(max(dot(normalize(p + vec2(0.00001)), normalize(response_origin + vec2(0.00001))), 0.0), 12.0);
    float impact = response_power * (0.026 * hit * sin(t * 4.8) + 0.012 * sin(t * 2.3));
    return 0.755 + activity * (w1 + w2 + w3 + slow_breath) + impact;
}

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float t = elapsed;
    float edge = radial_radius(p, t);
    float r = length(p);
    float rr = r / edge;
    float alpha = 1.0 - smoothstep(0.986, 1.018, rr);
    if (alpha <= 0.001) {
        COLOR = vec4(0.0);
    } else {
        // Spherical projection: helps the liquid look like a volumetric celestial body.
        float z = sqrt(max(0.0, 1.0 - min(rr * rr, 1.0)));
        vec3 n = normalize(vec3(p / edge * 0.84, z * 1.23));
        vec2 base_uv = p * (0.88 + 0.22 * z);

        // Domain warp: large masses flow slowly in opposing directions.
        float warp_a = texture(organic_noise, base_uv * 0.59 + vec2(t * 0.009, -t * 0.006)).g;
        float warp_b = texture(organic_noise, base_uv * 0.71 + vec2(-t * 0.007, t * 0.010)).b;
        vec2 warp = (vec2(warp_a, warp_b) - 0.5) * (0.58 * viscosity);
        vec2 field = base_uv * 1.43 + warp;
        float large = texture(organic_noise, field * 0.47 + vec2(t * 0.012, t * 0.005)).r;
        float medium = texture(organic_noise, field * 1.22 + vec2(-t * 0.011, t * 0.013)).g;
        float small = texture(organic_noise, field * 2.37 + vec2(t * 0.004, -t * 0.016)).b;
        float thin = 0.5;
        if (detail_level > 0.5) {
            thin = texture(organic_noise, field * 4.30 - vec2(t * 0.012, t * 0.007)).r;
        }

        // Viscous iridescent eddies (never blue oceans, continents or hard stripes).
        float phase = 6.2 * field.x + 4.2 * field.y + 8.0 * large + 3.3 * medium - t * 0.12;
        float marbling = 0.5 + 0.5 * sin(phase);
        float body = clamp(0.18 + 0.53 * large + 0.29 * medium, 0.0, 1.0);
        float luminous = smoothstep(0.56, 0.86, 0.45 * medium + 0.35 * small + 0.20 * marbling);
        float ribbons = pow(smoothstep(0.64, 0.96, marbling), 1.6) * (0.35 + 0.65 * large);
        float veins = max(0.0, thin - 0.57) * 0.16 * detail_level;
        vec3 pigment = mix(shadow_color.rgb, middle_color.rgb, smoothstep(0.26, 0.72, body));
        pigment = mix(pigment, liquid_color.rgb, clamp(0.20 * marbling + 0.72 * luminous + 0.30 * ribbons, 0.0, 0.85));
        pigment = mix(pigment, pearl_color.rgb, clamp(0.50 * ribbons + veins, 0.0, 0.65));

        vec3 light_dir = normalize(vec3(-0.39, -0.51, 0.80));
        vec3 half_dir = normalize(light_dir + vec3(0.0, 0.0, 1.0));
        float diffuse = 0.39 + 0.61 * max(dot(n, light_dir), 0.0);
        float specular = pow(max(dot(n, half_dir), 0.0), 28.0) * 0.63;
        float secondary_spec = pow(max(dot(n, normalize(vec3(0.66, 0.39, 0.8))), 0.0), 80.0) * 0.17;
        float rim = pow(clamp(1.0 - z, 0.0, 1.0), 2.3);
        float inner_light = (0.12 + luminous * 0.33 + ribbons * 0.28) * illumination;
        vec3 final_color = pigment * diffuse * illumination + liquid_color.rgb * inner_light;
        final_color += pearl_color.rgb * (specular + secondary_spec);
        final_color += liquid_color.rgb * (rim * 0.63) * illumination;
        // Pulsing local reaction radiates from the touched region.
        float dist_to_touch = length(p - response_origin);
        float concentric = exp(-pow((dist_to_touch - mod(t * 0.33, 1.35)) * 13.0, 2.0));
        final_color += pearl_color.rgb * concentric * response_power * 0.40;
        COLOR = vec4(clamp(final_color, vec3(0.0), vec3(1.0)), alpha);
    }
}

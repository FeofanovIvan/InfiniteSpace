shader_type canvas_item;
render_mode unshaded;

// Seamless 2:1 texture, generated offline; sampled as a rotating sphere.
uniform sampler2D surface_tex : source_color, filter_linear_mipmap, repeat_enable;
// Soft dynamic surface movement; solar spots remain on the rotating base map.
uniform sampler2D plasma_flow : filter_linear_mipmap, repeat_enable;
uniform float rotation_seconds : hint_range(4.0, 120.0, 0.5) = 22.0;
uniform float differential : hint_range(0.0, 0.40, 0.01) = 0.28;
uniform float activity : hint_range(0.0, 1.0, 0.01) = 0.30;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float radius_sq = dot(p, p);
    if (radius_sq >= 1.0) {
        COLOR = vec4(0.0);
    } else {
        // Hemisphere viewed along +z, NOT rotation of a flat disk.
        float z = sqrt(max(1.0 - radius_sq, 0.0));
        float latitude = asin(clamp(-p.y, -1.0, 1.0));
        float longitude = atan(p.x, z);
        // Equator faster than higher latitudes (stylized differential rotation).
        float speed = 1.0 - differential * pow(sin(latitude), 2.0);
        float phase = -TIME / max(rotation_seconds, 0.01) * speed;
        vec2 map_uv = vec2(fract(0.5 + longitude / 6.28318530718 + phase),
                            0.5 - latitude / 3.14159265359);
        vec3 surface = texture(surface_tex, map_uv).rgb;
        // Gentle plasma shimmer, not enough to erase recognizable sunspots.
        float flow_a = texture(plasma_flow, map_uv * vec2(3.0, 2.0) + vec2(TIME * 0.004, TIME * 0.0007)).r;
        float flow_b = texture(plasma_flow, map_uv * vec2(5.0, 3.0) - vec2(TIME * 0.002, TIME * 0.0012)).r;
        float pulse = 1.0 + activity * (0.26 * (flow_a - 0.5) + 0.14 * (flow_b - 0.5));
        // Softer brightness near the visible limb creates a spherical appearance.
        surface *= (0.80 + 0.20 * pow(z, 0.4)) * pulse;
        surface = mix(surface, vec3(1.0, 0.30, 0.025), 0.15 * (1.0 - z));
        float alpha = 1.0 - smoothstep(0.982, 1.0, radius_sq);
        COLOR = vec4(surface, alpha);
    }
}

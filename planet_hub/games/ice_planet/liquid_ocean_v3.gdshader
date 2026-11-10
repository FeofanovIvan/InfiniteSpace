shader_type canvas_item;
render_mode unshaded;

// Liquid-world teaching visualization: moving water, local crust/ice,
// sun-facing boiling, and bubbles. Reuses the project's real planet maps.
uniform sampler2D earth_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mars_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D neptune_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float surface_phase = 0.0;
uniform float hot_factor : hint_range(0.0, 1.0) = 0.0;
uniform float ice_factor : hint_range(0.0, 1.0) = 0.0;
uniform float solar_flare : hint_range(0.0, 1.0) = 0.0;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float RADIUS = 0.418;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float water_ripples(vec2 uv, float t) {
    float a = sin(uv.x * 52.0 + sin(uv.y * 15.0 + t * 0.66) * 2.8 + t * 1.45);
    float b = sin(uv.y * 39.0 - uv.x * 24.0 - t * 0.95);
    return (a * 0.6 + b * 0.4) * 0.5 + 0.5;
}

float bubble_ring(vec2 uv, float t) {
    vec2 grid = uv * vec2(11.0, 9.0);
    vec2 cell = floor(grid);
    float seed = hash21(cell);
    vec2 center = vec2(0.18 + 0.65 * hash21(cell + 3.2), 0.25 + 0.60 * hash21(cell + 8.7));
    center.y = fract(center.y - t * (0.15 + seed * 0.20));
    float radius = 0.10 + seed * 0.16;
    float delta = abs(length(fract(grid) - center) - radius);
    return (1.0 - smoothstep(0.013, 0.055, delta)) * (0.6 + 0.4 * seed);
}

void fragment() {
    vec2 p = (UV - vec2(0.5)) / RADIUS;
    p.y *= -1.0;
    float r = length(p);
    if (r > 1.09) {
        COLOR = vec4(0.0);
    } else if (r >= 1.0) {
        float rim = exp(-pow((r - 1.006) / 0.043, 2.0));
        float side = 1.0 - smoothstep(-0.55, 0.52, p.x);
        vec3 glow = mix(vec3(0.23, 0.78, 1.0), vec3(1.0, 0.45, 0.22), hot_factor * side);
        glow = mix(glow, vec3(0.85, 0.96, 1.0), ice_factor * (1.0 - side));
        COLOR = vec4(glow, rim * 0.50);
    } else {
        float z = sqrt(max(0.0, 1.0 - r * r));
        float longitude = atan(p.x, z);
        float latitude = asin(clamp(p.y, -1.0, 1.0));
        vec2 map_uv = vec2(fract(0.50 + longitude / TWO_PI + surface_phase / TWO_PI), 0.50 - latitude / PI);
        float t = TIME;
        float waves = water_ripples(map_uv * vec2(1.85, 1.32), t);
        vec3 earth = texture(earth_map, map_uv).rgb;
        vec3 mars = texture(mars_map, map_uv).rgb;
        vec3 neptune = texture(neptune_map, map_uv).rgb;
        float cloud_alpha = texture(cloud_map, map_uv + vec2(t * 0.0013, 0.0)).a;

        // Blue-violet living liquid, terrain features are barely visible beneath.
        vec3 water_deep = vec3(0.021, 0.15, 0.36);
        vec3 water_bright = vec3(0.10, 0.59, 0.87);
        vec3 water = mix(water_deep, water_bright, 0.38 + waves * 0.50);
        water = mix(water, earth, 0.17);
        water += vec3(0.055, 0.11, 0.15) * cloud_alpha;
        float sun_side = 1.0 - smoothstep(-0.55, 0.42, p.x);
        float night_side = smoothstep(-0.32, 0.57, p.x);
        // The face toward the sun BOILS; the opposite face FROSTS.
        float local_heat = clamp(hot_factor * (0.25 + 0.86 * sun_side), 0.0, 1.0);
        float local_ice = clamp(ice_factor * (0.25 + 0.86 * night_side), 0.0, 1.0);
        float boiling_noise = waves * 0.58 + hash21(floor(map_uv * vec2(65.0, 42.0))) * 0.42;
        vec3 lava = mix(mars * vec3(1.12, 0.49, 0.36), vec3(1.0, 0.29, 0.07), boiling_noise * 0.54 + 0.21);
        vec3 chilled = mix(neptune * vec3(0.60, 1.08, 1.13), vec3(0.87, 0.96, 1.0), 0.66 + waves * 0.22);
        float ice_cracks = step(0.77, water_ripples(map_uv * vec2(2.1, 1.6), 0.0));
        chilled = mix(chilled, vec3(0.98, 1.0, 1.0), ice_cracks * 0.25);
        vec3 color = mix(water, lava, local_heat);
        color = mix(color, chilled, local_ice * (1.0 - local_heat * 0.45));
        // Rings become visible and animate only inside the boiling portion.
        float bubbles = bubble_ring(map_uv, t);
        color += vec3(0.62, 0.29, 0.11) * bubbles * local_heat * 0.63;
        color += vec3(0.23, 0.32, 0.38) * bubbles * (1.0 - local_heat) * 0.11;
        color += solar_flare * vec3(0.27, 0.10, 0.012) * sun_side;
        // Globe volume, atmospheric rim and soft night-side shadow.
        float diffuse = 0.31 + 0.69 * (1.0 - 0.42 * p.x) * z;
        color *= clamp(diffuse, 0.25, 1.25);
        color += pow(1.0 - z, 3.1) * vec3(0.13, 0.52, 0.79);
        float alpha = 1.0 - smoothstep(0.989, 1.0, r);
        COLOR = vec4(color, alpha);
    }
}

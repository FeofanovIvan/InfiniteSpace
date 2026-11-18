shader_type canvas_item;
render_mode unshaded;

// Ice Planet: the actual MIKA surface textures, blended from Earth to Mars/Neptune.
uniform sampler2D earth_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mars_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D neptune_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D night_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float surface_phase = 0.0;
uniform float cloud_phase = 0.0;
uniform float hot_factor : hint_range(0.0, 1.0) = 0.0;
uniform float ice_factor : hint_range(0.0, 1.0) = 0.0;
uniform float solar_flare : hint_range(0.0, 1.0) = 0.0;
const float TAU_VALUE = 6.283185307179586;
const float PI_VALUE = 3.141592653589793;

vec2 globe_uv(vec3 normal, float phase) {
    float tilt = 0.4084;
    float cc = cos(tilt);
    float ss = sin(tilt);
    vec3 pole = vec3(normal.x * cc - normal.y * ss,
                     normal.x * ss + normal.y * cc, normal.z);
    float longitude = atan(pole.x, pole.z);
    float latitude = asin(clamp(pole.y, -1.0, 1.0));
    return vec2(fract(0.5 + longitude / TAU_VALUE + phase / TAU_VALUE),
                clamp(0.5 - latitude / PI_VALUE, 0.001, 0.999));
}

void fragment() {
    vec2 xy = (UV - vec2(0.5)) / 0.43;
    xy.y *= -1.0;
    float r = length(xy);
    if (r >= 1.0) {
        float halo = exp(-pow((r - 1.0) / 0.085, 2.0));
        halo *= 1.0 - smoothstep(1.11, 1.18, r);
        vec3 glow = mix(vec3(0.14, 0.58, 1.0), vec3(1.0, 0.33, 0.16), hot_factor);
        glow = mix(glow, vec3(0.57, 0.85, 1.0), ice_factor);
        COLOR = vec4(glow, clamp(halo * 0.30, 0.0, 0.34));
    } else {
        float z = sqrt(max(0.0, 1.0 - r * r));
        vec3 normal = vec3(xy, z);
        vec2 map_uv = globe_uv(normal, surface_phase);
        vec3 earth = texture(earth_map, map_uv).rgb;
        vec3 mars = texture(mars_map, map_uv).rgb;
        vec3 neptune = texture(neptune_map, map_uv).rgb;
        vec3 surface = mix(earth, mars, hot_factor);
        surface = mix(surface, neptune, ice_factor);
        vec3 light = normalize(vec3(-0.67, 0.20, 0.73));
        float ndotl = dot(normal, light);
        float illumination = 0.11 + 0.83 * max(ndotl, 0.0);
        vec3 rgb = surface * illumination;
        float daylight = smoothstep(-0.16, 0.13, ndotl);
        float clouds = texture(cloud_map, globe_uv(normal, cloud_phase)).a;
        rgb = mix(rgb, vec3(0.84, 0.94, 1.0) * (0.13 + 0.80 * max(ndotl, 0.0)),
                  clamp(clouds * 0.63 * (1.0 - hot_factor) * (1.0 - ice_factor * 0.60), 0.0, 0.80));
        rgb += texture(night_map, map_uv).rgb * (1.0 - daylight) * 1.3 * (1.0 - hot_factor) * (1.0 - ice_factor);
        float rim = pow(1.0 - z, 2.7) * clamp(ndotl + 0.54, 0.0, 1.0);
        rgb += mix(vec3(0.10, 0.46, 0.92), vec3(0.97, 0.43, 0.20), hot_factor) * rim * 0.5;
        rgb += vec3(1.0, 0.32, 0.06) * solar_flare * max(ndotl, 0.0) * 0.23;
        float alpha = 1.0 - smoothstep(0.991, 1.0, r);
        COLOR = vec4(rgb, alpha);
    }
}

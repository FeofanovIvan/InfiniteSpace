shader_type canvas_item;
render_mode unshaded;

// A purely 2D quad rendered as a shaded, rotating globe.
// The source textures use 2:1 equirectangular (longitude/latitude) mapping.
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D clouds_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D night_map : source_color, filter_linear_mipmap, repeat_enable;

uniform float surface_phase = 0.0; // radians, updated by Planet2D.gd
uniform float clouds_phase = 0.0;
uniform float axial_tilt = 0.4084; // 23.4 degrees
uniform vec3 light_direction = vec3(-0.65, 0.22, 0.73);
uniform bool show_clouds = true;
uniform bool show_night_lights = true;
uniform float cloud_opacity : hint_range(0.0, 2.0) = 0.95;
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.09;
uniform float atmosphere_strength : hint_range(0.0, 2.0) = 0.80;
uniform vec3 atmosphere_color : source_color = vec3(0.13, 0.53, 0.94);
uniform float night_lights_strength : hint_range(0.0, 6.0) = 3.0;

const float TAU_VALUE = 6.283185307179586;
const float PI_VALUE = 3.141592653589793;
const float RADIUS_UV = 0.42; // leaves 16% diameter for transparent corona

vec2 sphere_uv(vec3 direction, float phase) {
    // Rotate the globe's north pole within the screen plane for an apparent axial tilt.
    float cs = cos(axial_tilt);
    float sn = sin(axial_tilt);
    vec3 axis_space = vec3(
        direction.x * cs - direction.y * sn,
        direction.x * sn + direction.y * cs,
        direction.z
    );
    float longitude = atan(axis_space.x, axis_space.z);
    float latitude = asin(clamp(axis_space.y, -1.0, 1.0));
    return vec2(fract(0.5 + longitude / TAU_VALUE + phase / TAU_VALUE),
                clamp(0.5 - latitude / PI_VALUE, 0.001, 0.999));
}

void fragment() {
    vec2 xy = (UV - vec2(0.5)) / RADIUS_UV;
    xy.y *= -1.0; // 2D texture coordinates point down, sphere coordinates up.
    float radius = length(xy);
    vec3 sunlight = normalize(light_direction);

    // Rim scattering extends beyond the solid disc; fully transparent elsewhere.
    if (radius >= 1.0) {
        float outward_light = clamp(dot(normalize(xy + vec2(0.00001)), sunlight.xy) * 0.40 + 0.63, 0.0, 1.0);
        float d = (radius - 1.0) / 0.075;
        float glow = exp(-d * d) * outward_light * atmosphere_strength * 0.56;
        glow *= 1.0 - smoothstep(1.11, 1.17, radius);
        COLOR = vec4(atmosphere_color * 1.1, clamp(glow, 0.0, 0.75));
    } else {
        float z = sqrt(max(0.0, 1.0 - radius * radius));
        vec3 sphere_normal = vec3(xy, z);
        float ndotl = dot(sphere_normal, sunlight);
        float day_fade = smoothstep(-0.15, 0.12, ndotl);
        float diffuse = clamp(max(ndotl, 0.0) * 0.88 + ambient_strength, 0.0, 1.0);
        vec2 earth_uv = sphere_uv(sphere_normal, surface_phase);
        vec3 albedo = texture(surface_map, earth_uv).rgb;
        vec3 pixels = albedo * (diffuse * day_fade + ambient_strength * 0.28 * (1.0 - day_fade));

        if (show_night_lights) {
            vec3 lights = texture(night_map, earth_uv).rgb;
            pixels += lights * night_lights_strength * (1.0 - day_fade);
        }

        if (show_clouds) {
            vec2 cloud_uv = sphere_uv(sphere_normal, clouds_phase);
            float clouds = texture(clouds_map, cloud_uv).a * cloud_opacity;
            float cloud_light = (0.10 + 0.90 * max(ndotl, 0.0)) * day_fade + 0.13 * (1.0 - day_fade);
            float mixing = clamp(clouds * cloud_light, 0.0, 1.0);
            pixels = mix(pixels, vec3(0.85, 0.92, 1.0), mixing);
        }

        // Thin blue atmospheric limb, strongest near the illuminated edge.
        float limb = pow(1.0 - z, 2.5);
        float sun_rim = clamp(ndotl * 1.3 + 0.42, 0.0, 1.0);
        pixels += atmosphere_color * limb * sun_rim * atmosphere_strength * 0.72;
        // Smooth one-pixel outer contour. CanvasItem can remain transparent.
        float opacity = 1.0 - smoothstep(0.991, 1.0, radius);
        COLOR = vec4(pixels, opacity);
    }
}

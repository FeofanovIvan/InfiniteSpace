shader_type canvas_item;
render_mode unshaded;
uniform sampler2D metal_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D windows_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float phase = 0.0;
uniform vec3 light_direction = vec3(-0.55, -0.3, 0.82);
uniform float lights_strength : hint_range(0.0, 4.0) = 1.0;
uniform vec3 rim_color : source_color = vec3(0.24, 0.68, 0.84);
const float TAU_S = 6.28318530718;
void fragment() {
    vec2 p = (UV - vec2(0.5)) / 0.425;
    p.y = -p.y;
    float r = length(p);
    if (r >= 1.0) {
        COLOR = vec4(0.0);
    } else {
        float z = sqrt(max(0.0, 1.0 - r*r));
        vec3 norm = vec3(p, z);
        float longitude = atan(norm.x, norm.z);
        float latitude = asin(clamp(norm.y, -1.0, 1.0));
        vec2 atlas_uv = vec2(fract(0.5 + longitude/TAU_S + phase/TAU_S), clamp(0.5 - latitude/3.14159265,0.001,0.999));
        vec3 base = texture(metal_map, atlas_uv).rgb;
        vec3 emission = texture(windows_map, atlas_uv).rgb;
        vec3 light_vec = normalize(light_direction);
        float diffuse = max(dot(norm, light_vec), 0.0);
        float spec = pow(max(dot(reflect(-light_vec,norm), vec3(0.0,0.0,1.0)),0.0),32.0);
        float edge = pow(1.0-z,3.0);
        vec3 col = base * (0.23 + 0.81*diffuse);
        col += vec3(0.73,0.85,0.92)*spec*.8;
        col += emission * (0.35 + diffuse*.55)*lights_strength*1.5;
        col += rim_color * edge * 0.24;
        float opacity=1.0-smoothstep(0.989,1.0,r);
        COLOR = vec4(col,opacity);
    }
}

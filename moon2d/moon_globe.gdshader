shader_type canvas_item;
render_mode unshaded;
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float longitude_phase = 0.0;
uniform float spin_direction = 1.0;
uniform vec3 sunlight_direction = vec3(-0.42, 0.22, 0.88);
uniform vec3 light_tint : source_color = vec3(1.0, 0.97, 0.92);
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.17;
uniform float relief_strength : hint_range(0.0, 1.0) = 0.20;
uniform float silhouette_irregularity : hint_range(0.0, 1.0) = 0.0;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 haze_color : source_color = vec3(0.95, 0.65, 0.32);
const float PI_ = 3.14159265359;
const float TAU_ = 6.28318530718;
const float DISC = 0.403;
void fragment() {
    vec2 p = (UV - vec2(0.5)) / DISC;
    p.y = -p.y;
    float theta = atan(p.y, p.x);
    float irregular = 0.16*sin(theta*3.0+0.7) + 0.09*sin(theta*5.0+1.3) + 0.045*sin(theta*11.0);
    float limit = 1.0 + silhouette_irregularity * irregular;
    vec2 q = p / limit;
    float r = length(q);
    if (r >= 1.0) {
        COLOR = vec4(0.0);
    } else {
        float z = sqrt(max(0.0, 1.0-r*r));
        vec3 normal = vec3(q,z);
        vec2 uv = vec2(fract(0.5 + atan(normal.x,normal.z)/TAU_ + longitude_phase/TAU_), clamp(0.5-asin(clamp(normal.y,-1.0,1.0))/PI_,0.002,0.998));
        vec3 c = texture(surface_map, uv).rgb;
        float light = max(dot(normal,normalize(sunlight_direction)),0.0);
        float total = ambient_strength + light * 0.84;
        c *= clamp(total,0.0,1.2) * light_tint;
        // Subtle visible relief, derived from surface luminance; no fake huge embossing.
        vec3 detail = texture(surface_map, uv+vec2(0.0006,0.0003)).rgb;
        float small_detail = clamp(dot(c-detail,vec3(0.299,0.587,0.114)),-0.1,0.1);
        c *= 1.0 + small_detail*relief_strength;
        float haze = haze_strength * pow(1.0-z,2.5);
        c = mix(c,haze_color,haze*0.55);
        float edge = 1.0-smoothstep(0.989,1.0,r);
        COLOR = vec4(clamp(c,0.0,1.0),edge);
    }
}

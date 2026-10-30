shader_type canvas_item;
render_mode unshaded;
// Reusable mobile-safe sphere projection on a Sprite2D quad. All surface maps 2:1.
uniform sampler2D surface_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D emission_map : filter_linear_mipmap, repeat_enable;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;
uniform float direct_light_strength : hint_range(0.0, 2.0) = 1.0;
uniform float second_light_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 second_light_direction = vec3(0.75,0.18,0.40);
uniform vec3 second_light_color : source_color = vec3(1.0,0.83,0.59);
uniform float eclipse_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 eclipse_center = vec2(0.18,-0.15);
uniform float eclipse_radius = 0.24;
uniform float longitude_phase = 0.0;
uniform float cloud_phase = 0.0;
uniform float axial_tilt = 0.0;
uniform vec3 sunlight_direction = vec3(-0.50, 0.22, 0.83);
uniform vec3 star_light_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.18;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec3 atmosphere_color : source_color = vec3(0.2,0.6,0.9);
uniform float atmosphere_strength : hint_range(0.0, 2.0) = 0.6;
uniform float aurora_strength : hint_range(0.0, 2.0) = 0.0;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.0;
const float PI_ = 3.14159265359;
const float TAU_ = 6.28318530718;
const float DISC = 0.402;
vec2 world_uv(vec3 n, float phase) {
    float co=cos(axial_tilt); float si=sin(axial_tilt);
    vec3 tilted=vec3(n.x*co-n.y*si, n.x*si+n.y*co,n.z);
    float lon=atan(tilted.x,tilted.z);
    float lat=asin(clamp(tilted.y,-1.0,1.0));
    return vec2(fract(0.5+lon/TAU_+phase/TAU_), clamp(0.5-lat/PI_,0.001,0.999));
}
void fragment() {
    vec2 p=(UV-vec2(0.5))/DISC;
    p.y=-p.y;
    float r=length(p);
    vec3 light_dir=normalize(sunlight_direction);
    if (r >= 1.0) {
        float d=(r-1.0)/0.125;
        float glow=exp(-d*d*5.0) * atmosphere_strength * 0.50;
        glow*=1.0-smoothstep(1.14,1.23,r);
        float polar=abs(p.y/max(r,0.01));
        float aurora=aurora_strength * pow(polar,5.0)*exp(-pow((r-1.045)/0.046,2.0));
        vec3 glow_col=atmosphere_color * glow + vec3(0.08,0.99,0.65)*aurora;
        float alpha=clamp(glow+aurora,0.0,0.85);
        COLOR=vec4(clamp(glow_col,0.0,1.0),alpha);
    } else {
        float z=sqrt(max(0.0,1.0-r*r));
        vec3 n=vec3(p,z);
        float nd=dot(n,light_dir);
        float day=smoothstep(-0.17,0.22,nd);
        float primary = max(nd, 0.0) * direct_light_strength;
        float second = max(dot(n,normalize(second_light_direction)),0.0) * second_light_strength;
        float diffuse=ambient_strength + primary*0.88 + second*0.60;
        float eclipse_mask=1.0-eclipse_strength*(1.0-smoothstep(max(eclipse_radius-0.035,0.001),eclipse_radius+0.035,length(p-eclipse_center)));
        diffuse *= eclipse_mask;
        vec2 surface_uv=world_uv(n,longitude_phase);
        vec3 rgb=texture(surface_map,surface_uv).rgb;
        rgb*=clamp(diffuse,0.0,1.3)*mix(vec3(0.55,0.63,0.79),star_light_tint,day);
        rgb+=texture(surface_map,surface_uv).rgb*second_light_color*second*0.12;
        vec2 clouds_uv=world_uv(n,cloud_phase);
        vec4 cloud=texture(cloud_map,clouds_uv);
        float mixing=clamp(cloud.a*cloud_opacity*(0.20+0.8*day),0.0,0.92);
        rgb=mix(rgb,cloud.rgb*star_light_tint*(0.35+primary),mixing);
        float limb=pow(1.0-z,3.2);
        float scatter=clamp(nd*1.2+0.46,0.0,1.0);
        rgb+=atmosphere_color*limb*scatter*atmosphere_strength*0.75;
        rgb += vec3(0.13,0.61,1.0)*texture(emission_map,surface_uv).r*emission_strength;
        // M33: both-star lighting is used by Svetara; eclipse is an optional event only.
        float polar=pow(abs(n.y),10.0);
        float flicker=0.7+0.3*sin(18.0*surface_uv.x+TIME*0.65);
        rgb+=vec3(0.05,0.9,0.61)*polar*aurora_strength*flicker*(0.1+0.9*limb);
        // Optional slight haze retains a legible silhouette on mobile.
        rgb=mix(rgb,atmosphere_color,clamp(haze_strength*limb*0.58,0.0,0.5));
        float opacity=1.0-smoothstep(0.992,1.0,r);
        COLOR=vec4(clamp(rgb,0.0,1.0),opacity);
    }
}

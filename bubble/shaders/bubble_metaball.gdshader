shader_type canvas_item;
render_mode unshaded;

// One continuous, animated 2D liquid membrane for all room locomotion.
// The five lobes are *not* overlaid circles: all volumes are united by SDF
// smooth union. Moving them separates/merges liquid with no sprite swapping.
uniform vec2 canvas_size = vec2(800.0, 650.0);
uniform vec2 core_size = vec2(1.0, 1.0);
uniform float core_radius = 147.0;
uniform float anim_time = 0.0;
uniform float quiet_level : hint_range(0.0, 1.0) = 0.0;
uniform float dirty_level : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.68;
uniform float liquid_activity : hint_range(0.0, 1.0) = 0.62;

uniform float meal_opaque : hint_range(0.0, 1.0) = 0.0;

uniform vec4 sat0 = vec4(-145.0, -75.0, 52.0, 57.0);
uniform vec4 sat1 = vec4(145.0, -83.0, 48.0, 57.0);
uniform vec4 sat2 = vec4(122.0, 114.0, 53.0, 57.0);
uniform vec4 sat3 = vec4(-129.0, 116.0, 46.0, 57.0);
uniform vec4 sat4 = vec4(24.0, -158.0, 26.0, 39.0);
uniform vec4 bridge = vec4(0.0, 0.0, 26.0, 25.0);
uniform float bridge_enabled = 0.0;

float soft_union(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / max(k, 0.001);
    return min(a, b) - 0.25 * h * h * k;
}
float ball_sd(vec2 p, vec2 c, float r) {
    return length(p-c) - r;
}
float core_sd(vec2 p) {
    vec2 q = p / max(core_size, vec2(0.36));
    float a = atan(q.y,q.x);
    float amplitude = (0.35 + 0.65 * liquid_activity) * (1.0 - 0.53 * quiet_level);
    float wave1 = 6.0 * sin(a * 5.0 + anim_time * 1.25);
    float wave2 = 4.2 * sin(a * 8.0 - anim_time * 1.53 + 0.40);
    float wave3 = 2.3 * cos(a * 3.0 + anim_time * 0.60);
    float breath = 3.8 * sin(anim_time * 0.93);
    return (length(q) - core_radius - (wave1+wave2+wave3)*amplitude - breath) * min(core_size.x,core_size.y);
}
vec2 flow_warp(vec2 p) {
    float a = liquid_activity * (1.0 - quiet_level * 0.52);
    return p + vec2(
      sin(p.y * 0.021 + anim_time * 1.37) * 3.3 + sin(p.x * 0.010 - anim_time * 0.74) * 2.0,
      cos(p.x * 0.018 + anim_time * 1.09) * 2.8 + cos(p.y * 0.014 - anim_time * 0.85) * 2.1
    ) * a;
}
float body_sd(vec2 p) {
    float d=core_sd(p);
    d=soft_union(d,ball_sd(p,sat0.xy,sat0.z),sat0.w);
    d=soft_union(d,ball_sd(p,sat1.xy,sat1.z),sat1.w);
    d=soft_union(d,ball_sd(p,sat2.xy,sat2.z),sat2.w);
    d=soft_union(d,ball_sd(p,sat3.xy,sat3.z),sat3.w);
    d=soft_union(d,ball_sd(p,sat4.xy,sat4.z),sat4.w);
    if (bridge_enabled > 0.5) { d=soft_union(d,ball_sd(p,bridge.xy,bridge.z),bridge.w); }
    return d;
}
void fragment() {
    vec2 p = UV * canvas_size - canvas_size * 0.5;
    vec2 q = flow_warp(p);
    float d = body_sd(q);
    float aa = max(fwidth(d), 1.2);
    float mask = 1.0 - smoothstep(-aa, aa, d);

    // Recover local curved shading coordinates of the nearest organic lobe.
    vec2 local = q / max(core_radius * core_size, vec2(0.1));
    float nearest_d=core_sd(q);
    float d0=ball_sd(q,sat0.xy,sat0.z);
    float d1=ball_sd(q,sat1.xy,sat1.z);
    float d2=ball_sd(q,sat2.xy,sat2.z);
    float d3=ball_sd(q,sat3.xy,sat3.z);
    float d4=ball_sd(q,sat4.xy,sat4.z);
    if(d0<nearest_d){nearest_d=d0; local=(q-sat0.xy)/max(sat0.z,1.0);}
    if(d1<nearest_d){nearest_d=d1; local=(q-sat1.xy)/max(sat1.z,1.0);}
    if(d2<nearest_d){nearest_d=d2; local=(q-sat2.xy)/max(sat2.z,1.0);}
    if(d3<nearest_d){nearest_d=d3; local=(q-sat3.xy)/max(sat3.z,1.0);}
    if(d4<nearest_d){nearest_d=d4; local=(q-sat4.xy)/max(sat4.z,1.0);}
    local=clamp(local,vec2(-1.35),vec2(1.35));
    float z=sqrt(max(0.025,1.0-min(dot(local,local),0.98)));
    vec3 n=normalize(vec3(local*0.69,z));
    float diffuse=max(dot(n,normalize(vec3(-0.48,-0.68,0.78))),0.0);
    float spec=pow(diffuse,19.0);
    float pearl_wave=0.5+0.5*sin(local.y*6.1-local.x*3.7+anim_time*0.37);
    float color_drift=0.5+0.5*cos(local.x*4.1+local.y*3.2-anim_time*0.28);
    vec3 violet=vec3(0.68,0.66,0.97);
    vec3 aqua=vec3(0.39,0.85,0.99);
    vec3 white=vec3(0.93,0.97,1.0);
    vec3 shell=mix(violet,aqua,0.22+0.54*pearl_wave);
    shell=mix(shell,white,0.20+0.22*diffuse+0.08*color_drift);
    // Highlights are painted in body space, following the animated membrane.
    vec2 glint_uv=(local-vec2(-0.38,-0.47))*vec2(3.8,6.2);
    float glint=exp(-dot(glint_uv,glint_uv));
    float edge=exp(-abs(d+1.8)/5.2);
    float outer_rim=exp(-abs(d-0.3)/2.7);
    shell += vec3(0.10,0.12,0.18)*spec;
    shell=mix(shell,white,clamp(glint*0.69+edge*0.37,0.0,0.85));
    shell += vec3(0.025,0.10,0.12)*glow_strength*outer_rim;
    shell=mix(shell,vec3(0.46,0.47,0.62),dirty_level*0.60);
    float translucency=0.79+0.13*diffuse+0.07*edge;
    COLOR=vec4(clamp(shell,vec3(0.0),vec3(1.0)),mask*mix(clamp(translucency,0.0,0.99),1.0,meal_opaque));
}

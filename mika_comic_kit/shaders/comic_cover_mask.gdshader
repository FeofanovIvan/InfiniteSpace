shader_type canvas_item;
render_mode unshaded, blend_mix;
// One image always covers the full landscape viewport. Real-valued focus and zoom.
uniform sampler2D picture : source_color, repeat_disable, filter_linear;
uniform vec2 canvas_size = vec2(1280.0,720.0);
uniform vec2 focus = vec2(0.5,0.5);
uniform float camera_zoom = 1.0;
uniform vec2 shake_px = vec2(0.0);
uniform int mask_kind = 0;
// 0 FULL; 1 LEFT_DIAGONAL; 2 RIGHT_DIAGONAL; 3 RECT; 4 CIRCLE; 5 TOP/BOTTOM SPLIT
uniform vec4 mask_rect = vec4(0.0,0.0,1.0,1.0);
uniform float seam = 0.5;
uniform float slope = 0.12;
uniform float radius = 0.5;
uniform vec2 reveal_center = vec2(0.5,0.5);
uniform float opacity = 1.0;
uniform float gutter_width = 0.004;
uniform vec4 gutter_color : source_color = vec4(1.0,0.9,0.96,1.0);

float inside_box(vec2 p, vec4 box) {
    return step(box.x,p.x) * step(box.y,p.y) * step(p.x,box.x+box.z) * step(p.y,box.y+box.w);
}

void fragment() {
    vec2 dim = max(canvas_size, vec2(1.0));
    vec2 px = UV * dim - shake_px;
    vec2 uv_screen = px / dim;
    vec2 source_size = vec2(textureSize(picture,0));
    float factor = max(dim.x/source_size.x,dim.y/source_size.y) * max(camera_zoom,0.01);
    vec2 view_extent = dim / factor;
    vec2 src_center = clamp(focus * source_size,view_extent*0.5,source_size-view_extent*0.5);
    vec2 src_uv = (src_center + (uv_screen-vec2(0.5))*view_extent) / source_size;
    vec4 image_color = texture(picture,clamp(src_uv,vec2(0.0),vec2(1.0)));
    float mask_value = 1.0;
    float border_value = 0.0;
    if (mask_kind == 1 || mask_kind == 2) {
        float dist = uv_screen.x-(seam+(uv_screen.y-0.5)*slope);
        mask_value = mask_kind == 1 ? 1.0-smoothstep(-0.001,0.001,dist) : smoothstep(-0.001,0.001,dist);
        border_value = 1.0-smoothstep(gutter_width*0.5,gutter_width*1.1,abs(dist));
    } else if (mask_kind == 3) {
        mask_value = inside_box(uv_screen,mask_rect);
        vec2 d = min(uv_screen-mask_rect.xy,mask_rect.xy+mask_rect.zw-uv_screen);
        float distance_to_edge = min(min(d.x,d.y),1000.0);
        border_value = mask_value*(1.0-smoothstep(0.0,gutter_width,distance_to_edge));
    } else if (mask_kind == 4) {
        float dist = distance(uv_screen,reveal_center);
        mask_value = 1.0-smoothstep(radius-0.002,radius+0.002,dist);
        border_value = 1.0-smoothstep(gutter_width*0.2,gutter_width*1.2,abs(dist-radius));
    } else if (mask_kind == 5) {
        mask_value = inside_box(uv_screen,mask_rect);
    }
    vec3 color_out = mix(image_color.rgb,gutter_color.rgb,border_value);
    COLOR = vec4(color_out,image_color.a * opacity * max(mask_value,border_value));
}

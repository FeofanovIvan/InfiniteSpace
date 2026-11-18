shader_type canvas_item;

// The panel defines the geometry. The image never affects its dimensions.
// "Cover" preserves the image aspect ratio and crops whichever axis overflows.
uniform sampler2D stage_texture : source_color, filter_linear, repeat_disable;
uniform vec2 source_size = vec2(1672.0, 941.0);
uniform vec2 panel_size = vec2(1200.0, 520.0);
uniform float corner_radius = 27.0;

void fragment() {
    float panel_aspect = panel_size.x / max(panel_size.y, 1.0);
    float image_aspect = source_size.x / max(source_size.y, 1.0);
    vec2 image_uv = UV;
    if (image_aspect > panel_aspect) {
        image_uv.x = 0.5 + (UV.x - 0.5) * (panel_aspect / image_aspect);
    } else {
        image_uv.y = 0.5 + (UV.y - 0.5) * (image_aspect / panel_aspect);
    }
    vec4 pixel = texture(stage_texture, image_uv);
    vec2 p = UV * panel_size;
    vec2 r = panel_size * 0.5;
    float radius = min(corner_radius, min(r.x, r.y));
    vec2 q = abs(p - r) - (r - vec2(radius));
    float rounded_distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float opacity = 1.0 - smoothstep(-1.0, 1.0, rounded_distance);
    COLOR = vec4(pixel.rgb, pixel.a * opacity);
}

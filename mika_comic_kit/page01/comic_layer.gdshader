shader_type canvas_item;
render_mode unshaded, blend_mix;

// One GPU-resampled illustration layer. All camera coordinates stay float.
// The mask and the thin comic gutter share the same floating-point seam.
// Layout coordinates are a fixed 1280x720 virtual 16:9 frame.
uniform sampler2D artwork : source_color, repeat_disable, filter_linear;
uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5, 0.5);
uniform float panel_start_x = 0.0; // only >0 for right-hand panel artwork
uniform int mask_mode = 0;        // 0 full; 1 right; 2 left; 3 bottom
uniform float seam_px = 0.0;
uniform float slope = 0.0;
uniform float border_px = 4.0;
uniform vec2 shake_px = vec2(0.0);
uniform vec4 gutter_color : source_color = vec4(1.0, 0.91, 0.98, 1.0);

float edge_alpha(float dist, float aa) {
    return smoothstep(-aa, aa, dist);
}

void fragment() {
    const vec2 FRAME = vec2(1280.0, 720.0);
    // Shaking the virtual viewing coordinates shifts every panel and seam
    // together. Camera motion without shake never uses integer coordinates.
    vec2 pixel = UV * FRAME - shake_px;
    float start_px = panel_start_x;
    float panel_width = FRAME.x - start_px;
    vec2 panel_px = vec2(pixel.x - start_px, pixel.y);

    vec2 src = vec2(textureSize(artwork, 0));
    float cover_scale = max(panel_width / src.x, FRAME.y / src.y) * zoom;
    vec2 view = vec2(panel_width, FRAME.y) / cover_scale;
    vec2 center_src = clamp(focus * src, view * 0.5, src - view * 0.5);
    vec2 source_uv = (center_src + (panel_px - vec2(panel_width, FRAME.y) * 0.5) / cover_scale) / src;
    vec4 ink = texture(artwork, clamp(source_uv, vec2(0.0), vec2(1.0)));

    if (mask_mode == 0) {
        COLOR = vec4(ink.rgb, 1.0);
        return;
    }

    float distance_to_panel = 0.0;
    if (mask_mode == 1) {
        distance_to_panel = pixel.x - (seam_px + (pixel.y - 360.0) * slope);
    } else if (mask_mode == 2) {
        distance_to_panel = (seam_px + (pixel.y - 360.0) * slope) - pixel.x;
    } else if (mask_mode == 3) {
        distance_to_panel = pixel.y - (seam_px + (pixel.x - 640.0) * slope);
    }
    float panel_alpha = edge_alpha(distance_to_panel, 0.65);
    float border_alpha = 1.0 - smoothstep(max(0.0, border_px * 0.5 - 0.75), border_px * 0.5 + 0.75, abs(distance_to_panel));
    float out_alpha = max(panel_alpha, border_alpha);
    COLOR = vec4(mix(ink.rgb, gutter_color.rgb, border_alpha), out_alpha);
}

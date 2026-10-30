shader_type canvas_item;
render_mode unshaded, blend_mix;
// Expanded artwork, registered back to the approved ORIGINAL camera coordinates.
// The 16:9 director's timeline, focus, zoom, panel shapes and shake are unchanged.
uniform sampler2D artwork : source_color, repeat_disable, filter_linear;
uniform float zoom = 1.0;
uniform vec2 focus = vec2(0.5, 0.5);
uniform float panel_start_x = 0.0;
uniform int mask_mode = 0;
uniform float seam_px = 0.0;
uniform float slope = 0.0;
uniform float border_px = 4.0;
uniform vec2 shake_px = vec2(0.0);
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform float contain_scale = 1.0;
uniform vec2 source_resolution = vec2(1536.0, 1024.0);
// M = [[a,b],[c,d]]; expanded_px = M * original_px + origin.
uniform vec4 composition_affine = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec2 composition_origin = vec2(0.0, 0.0);
uniform vec4 gutter_color : source_color = vec4(1.0, 0.91, 0.98, 1.0);

float edge_alpha(float dist, float aa) {
    return smoothstep(-aa, aa, dist);
}

void fragment() {
    const vec2 FRAME = vec2(1280.0, 720.0);
    vec2 safe_view = max(viewport_size, vec2(1.0));
    float safe_scale = max(contain_scale, 0.0001);
    // A 16:9 virtual director's frame is centered with NO cropping at any ratio.
    vec2 pixel = (UV * safe_view - safe_view * 0.5) / safe_scale + FRAME * 0.5 - shake_px;
    float start_px = panel_start_x;
    float panel_width = max(1.0, FRAME.x - start_px);
    vec2 panel_px = vec2(pixel.x - start_px, pixel.y);
    vec2 src = max(source_resolution, vec2(1.0));
    // IMPORTANT: compute old camera COVER from old SOURCE dimensions, NOT expanded PNG.
    float image_cover = max(panel_width / src.x, FRAME.y / src.y) * zoom;
    vec2 frame_view = vec2(panel_width, FRAME.y) / max(image_cover, 0.001);
    vec2 center_src = clamp(focus * src, frame_view * 0.5,
        max(frame_view * 0.5, src - frame_view * 0.5));
    vec2 original_px = center_src +
        (panel_px - vec2(panel_width, FRAME.y) * 0.5) / max(image_cover, 0.001);
    // Reproject original director's camera coordinates to the nine expanded PNGs.
    vec2 expanded_px = vec2(
        composition_affine.x * original_px.x + composition_affine.y * original_px.y,
        composition_affine.z * original_px.x + composition_affine.w * original_px.y
    ) + composition_origin;
    vec2 uv_expanded = expanded_px / vec2(textureSize(artwork, 0));
    // Use the newly authored extra artwork wherever available; mirror ONLY beyond
    // the expanded image's outer edge as a last resort to avoid black gutters.
    vec2 sampled_uv = 1.0 - abs(mod(uv_expanded, 2.0) - 1.0);
    vec4 ink = texture(artwork, sampled_uv);

    float distance_to_panel = 1e6;
    if (mask_mode == 1) {
        distance_to_panel = pixel.x - (seam_px + (pixel.y - 360.0) * slope);
    } else if (mask_mode == 2) {
        distance_to_panel = (seam_px + (pixel.y - 360.0) * slope) - pixel.x;
    } else if (mask_mode == 3) {
        distance_to_panel = pixel.y - (seam_px + (pixel.x - 640.0) * slope);
    }
    if (mask_mode == 0) {
        COLOR = vec4(ink.rgb, 1.0);
    } else {
        float panel_alpha = edge_alpha(distance_to_panel, 0.65);
        float border_alpha = 1.0 - smoothstep(max(0.0, border_px * 0.5 - 0.75),
            border_px * 0.5 + 0.75, abs(distance_to_panel));
        float out_alpha = max(panel_alpha, border_alpha);
        COLOR = vec4(mix(ink.rgb, gutter_color.rgb, border_alpha), out_alpha);
    }
}

shader_type canvas_item;
// CH01 P01 only. Two camera UVs allow a brief dissolve between page rows,
// while shots within one row use one continuous pan over the same full page.
uniform sampler2D artwork : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 focus_a = vec2(0.30, 0.14);
uniform float crop_height_a = 0.24;
uniform vec2 focus_b = vec2(0.30, 0.14);
uniform float crop_height_b = 0.24;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float page_aspect = 0.707;
uniform float viewport_aspect = 1.777778;

vec2 page_uv(vec2 screen_uv, vec2 center, float visible_height) {
    float h = min(max(visible_height, 0.001), min(1.0, page_aspect / max(viewport_aspect, 0.001)));
    float w = h * viewport_aspect / max(page_aspect, 0.001);
    vec2 extent = vec2(w, h);
    vec2 allowed_center = clamp(center, extent * 0.5, vec2(1.0) - extent * 0.5);
    return allowed_center + (screen_uv - vec2(0.5)) * extent;
}

void fragment() {
    vec2 uv_a = page_uv(UV, focus_a, crop_height_a);
    vec4 first = texture(artwork, uv_a);
    if (dissolve < 0.0001) {
        COLOR = first;
    } else {
        vec2 uv_b = page_uv(UV, focus_b, crop_height_b);
        vec4 second = texture(artwork, uv_b);
        COLOR = mix(first, second, clamp(dissolve, 0.0, 1.0));
    }
}

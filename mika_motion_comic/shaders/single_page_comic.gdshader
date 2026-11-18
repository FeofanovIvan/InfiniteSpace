shader_type canvas_item;

uniform sampler2D artwork : source_color, filter_linear_mipmap_anisotropic;
uniform vec2 focus = vec2(0.5, 0.5);
uniform float crop_height : hint_range(0.08, 1.0) = 0.25;
uniform float page_aspect = 0.707;
uniform float viewport_aspect = 1.7777778;
uniform float exposure : hint_range(0.5, 1.5) = 1.0;

void fragment() {
	float safe_page_aspect = max(page_aspect, 0.001);
	float crop_width = crop_height * viewport_aspect / safe_page_aspect;
	vec2 crop_size = vec2(crop_width, crop_height);
	vec2 limited_focus = clamp(focus, crop_size * 0.5, vec2(1.0) - crop_size * 0.5);
	vec2 page_uv = limited_focus + (UV - vec2(0.5)) * crop_size;
	vec4 sampled = texture(artwork, page_uv);
	COLOR = vec4(sampled.rgb * exposure, sampled.a);
}

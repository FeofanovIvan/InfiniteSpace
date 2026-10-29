shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float animation_time = 0.0;
void fragment() {
    vec4 disk = texture(TEXTURE, UV);
    // Optical image stays in place. Just a very slow (1.2%) light variation.
    float shimmer = 0.994 + 0.006 * sin(animation_time * 0.27 + UV.x * 7.0);
    COLOR = vec4(disk.rgb * shimmer, disk.a);
}

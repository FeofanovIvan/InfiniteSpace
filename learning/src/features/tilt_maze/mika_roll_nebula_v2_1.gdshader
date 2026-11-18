shader_type canvas_item;
render_mode unshaded, blend_mix;

// This is atmospheric scenery OUTSIDE the round labyrinth, never a floor.
// The original InfiniteSpace stars remain legible behind it.
uniform vec2 viewport_px = vec2(1280.0, 720.0);
uniform vec2 labyrinth_center_px = vec2(640.0, 410.0);
uniform float labyrinth_radius_px = 310.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec2 pos = UV * viewport_px;
    float t = TIME * 0.027;
    vec2 a = (pos - vec2(viewport_px.x * 0.12, viewport_px.y * 0.54)) / vec2(max(viewport_px.x * 0.34, 1.0), max(viewport_px.y * 0.76, 1.0));
    vec2 b = (pos - vec2(viewport_px.x * 0.91, viewport_px.y * 0.27)) / vec2(max(viewport_px.x * 0.42, 1.0), max(viewport_px.y * 0.66, 1.0));
    vec2 c = (pos - vec2(viewport_px.x * 0.77, viewport_px.y * 0.91)) / vec2(max(viewport_px.x * 0.39, 1.0), max(viewport_px.y * 0.48, 1.0));
    float cloud_a = exp(-dot(a, a) * 2.7);
    float cloud_b = exp(-dot(b, b) * 2.9);
    float cloud_c = exp(-dot(c, c) * 3.2);
    float soft_ribbon = 0.82 + 0.18 * sin(pos.x * 0.012 + pos.y * 0.018 + sin(pos.y * 0.014) * 1.9 + t);
    // This mask guarantees cloud opacity is practically zero over the maze.
    float dist = distance(pos, labyrinth_center_px);
    float peripheral = smoothstep(labyrinth_radius_px * 0.99, labyrinth_radius_px * 1.32, dist);
    vec3 color = vec3(0.20, 0.52, 0.97) * cloud_a + vec3(0.60, 0.29, 0.95) * cloud_b + vec3(0.14, 0.75, 0.82) * cloud_c;
    float alpha = clamp((cloud_a * 0.15 + cloud_b * 0.12 + cloud_c * 0.11) * soft_ribbon * brightness, 0.0, 0.34);
    COLOR = vec4(color * 1.12, alpha * peripheral);
}

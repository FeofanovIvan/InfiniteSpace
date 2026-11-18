extends RefCounted
## Shared layout & styling of the REAL Simulator back button, PlanetHub crystal
## counter, and middle caption plaque. All three are aligned to the counter.
## This script does not recreate or replace those two native UI components.

const PANEL_FILL := Color(0.020, 0.105, 0.245, 0.88)
const PANEL_OUTLINE := Color("#65e7ff")

static func apply_title_style(panel: Panel) -> void:
    if panel == null:
        return
    var style := StyleBoxFlat.new()
    style.anti_aliasing = true
    style.bg_color = PANEL_FILL
    style.border_color = PANEL_OUTLINE
    style.set_border_width_all(3)
    style.set_corner_radius_all(24)
    style.shadow_color = Color(0.18, 0.69, 1.0, 0.42)
    style.shadow_size = 10
    style.shadow_offset = Vector2.ZERO
    panel.add_theme_stylebox_override("panel", style)

static func relayout(view: Vector2, safe: Rect2, back: Control, hub: Control, title_panel: Panel, title_label: Label, subtitle_label: Label) -> float:
    if back == null or hub == null or title_panel == null or title_label == null or subtitle_label == null:
        return 0.0
    if view.x <= 90.0 or view.y <= 90.0 or safe.size.x <= 90.0:
        return 0.0

    var sw: float = safe.size.x
    var sh: float = safe.size.y
    var scale_unit: float = minf(view.x / 1680.0, view.y / 864.0)
    var margin: float = clampf(sw * 0.018, 5.0, 28.0)
    var gap: float = clampf(sw * 0.015, 5.0, 22.0)
    # Ensure there is always a center title between the two native elements.
    var minimum_title: float = minf(260.0 * scale_unit, sw * 0.32)
    var required: float = 158.0 * 0.60 + 394.0 * 0.80 + minimum_title / maxf(scale_unit, 0.01)
    var width_limit: float = maxf(0.08, (sw - 2.0 * margin - 2.0 * gap) / required)
    var s: float = minf(scale_unit, width_limit)
    var counter_scale: float = s * 0.80
    var back_size: float = s * 158.0 * 0.60
    var counter_height: float = s * 158.0 * 0.80
    var counter_width: float = s * 394.0 * 0.80
    var top: float = safe.position.y + clampf(sh * 0.022, 5.0, 22.0)
    var left: float = safe.position.x + margin
    var right: float = safe.end.x - margin
    var counter_left: float = right - counter_width

    back.position = Vector2(left, top + (counter_height - back_size) * 0.5)
    back.size = Vector2.ONE * back_size

    # The counter belongs to BottomHUD (1680x158). Only its ORIGINAL center
    # section (394 px wide, centered at x=643) remains visible and is placed
    # flush to the right. Uniform scaling preserves the reference artwork.
    hub.size = Vector2(1680.0, 158.0)
    hub.scale = Vector2.ONE * counter_scale
    hub.position = Vector2(counter_left - 643.0 * counter_scale, top)

    var title_left: float = left + back_size + gap
    var title_right: float = counter_left - gap
    var title_width: float = maxf(32.0, title_right - title_left)
    title_panel.position = Vector2(title_left, top)
    title_panel.size = Vector2(title_width, counter_height)
    var main_font: int = maxi(10, roundi(39.0 * s))
    var char_count: int = maxi(1, title_label.text.length())
    if char_count > 18:
        main_font = maxi(9, roundi(float(main_font) * 18.0 / float(char_count)))
    title_label.position = Vector2(6.0, counter_height * 0.055)
    title_label.size = Vector2(maxf(26.0, title_width - 12.0), counter_height * 0.60)
    title_label.add_theme_font_size_override("font_size", main_font)
    subtitle_label.position = Vector2(6.0, counter_height * 0.66)
    subtitle_label.size = Vector2(maxf(26.0, title_width - 12.0), counter_height * 0.28)
    subtitle_label.add_theme_font_size_override("font_size", maxi(8, roundi(17.0 * s)))
    subtitle_label.visible = title_width >= 170.0
    return top + counter_height

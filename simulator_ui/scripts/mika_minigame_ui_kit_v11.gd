extends RefCounted
## MIKA shared UI kit / v1 — intended for all educational mini-games.
## Source palette: PlanetHub bottom_hud.gd and MikoMainMenu._style_back_button.

const NAVY: Color = Color("#061c38")
const CYAN: Color = Color("#26dfff")
const PAPER: Color = Color("#eefbff")
const MUTED: Color = Color("#9dc7d8")
const SUCCESS: Color = Color("#96ffd3")

const BLUE_CRYSTAL_PATH: String = "res://planet_hub/assets/v68_neon/crystal_reference.png"
const CRYSTAL_CAPSULE_PATH: String = "res://planet_hub/assets/v68_neon/crystals_panel.png"
const SHARED_BACK_GLYPH_PATH: String = "res://simulator_ui/back_arrow_glyph.gd"
const SPACE_BACKGROUND_PATH: String = "res://simulator_ui/scripts/real_space_background.gd"

static func button_style(hovered: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#113a60") if hovered else NAVY
    style.border_color = CYAN
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    style.shadow_color = Color(0.04, 0.64, 1.0, 0.38)
    style.shadow_size = 6
    style.anti_aliasing = true
    return style

static func stage_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.07, 0.15, 0.79)
    style.border_color = CYAN
    style.set_border_width_all(2)
    style.set_corner_radius_all(36)
    style.shadow_color = Color(0.01, 0.61, 0.95, 0.32)
    style.shadow_size = 9
    style.anti_aliasing = true
    return style

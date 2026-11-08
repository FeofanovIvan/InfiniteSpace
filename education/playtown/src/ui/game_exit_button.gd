class_name GameExitButton
extends Button

const EXIT_ICON: Texture2D = preload("res://education/playtown/assets/ui/home_button.png")


func _init() -> void:
	text = ""
	icon = EXIT_ICON
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", _style(Color("#fff4d1"), Color("#d89b35"), 0.0))
	add_theme_stylebox_override("hover", _style(Color("#fff9e8"), Color("#e2a43c"), 1.0))
	add_theme_stylebox_override("pressed", _style(Color("#f1d58f"), Color("#c68122"), 2.0))
	add_theme_stylebox_override("disabled", _style(Color("#eadfbe"), Color("#b99a63"), 0.0))


func _style(fill: Color, border: Color, pressed_offset: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0 + pressed_offset
	style.content_margin_bottom = 10.0 - pressed_offset
	style.shadow_color = Color(0.32, 0.18, 0.08, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 5.0)
	return style

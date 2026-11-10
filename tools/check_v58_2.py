#!/usr/bin/env python3
"""Static invariants for the standalone swipe-only Play Town card gallery."""
from pathlib import Path
r = Path(__file__).resolve().parent.parent
p = r / 'scripts/MikoMainMenu.gd'
s = p.read_text(encoding='utf-8')
assert 'func _load_original_catalog() -> void:' in s
assert '_cards.append(info)' in s
assert 'var button: TextureButton = TextureButton.new()' in s
assert 'button.texture_normal = load(art_path) as Texture2D' in s
assert 'button.pressed.connect(_open_game.bind(scene_path))' in s
assert 'button.mouse_filter = Control.MOUSE_FILTER_IGNORE' in s
assert 'var _gesture_layer: Control' in s
assert '_gesture_layer.name = "TransparentSwipeAndTapArea"' in s
assert 'ScrollContainer.SCROLL_MODE_SHOW_NEVER' in s
assert 'ScrollContainer.SCROLL_MODE_DISABLED' in s
assert 'InputEventScreenTouch' in s and 'InputEventScreenDrag' in s
assert 'InputEventMouseButton' in s and 'InputEventMouseMotion' in s
assert 'InputEventPanGesture' in s
assert 'func _gesture_begin(' in s and 'func _gesture_end(' in s
assert 'screen_point.distance_to(_pointer_origin) > DRAG_THRESHOLD' in s
assert 'clicked.pressed.emit()' in s
assert '_fling_speed *= exp(-6.0 * delta)' in s
assert '_return_to_cards()' in s
assert 'crystals_earned.emit(gained)' in s
assert 'SubViewportContainer.new()' in s
assert 'StyleBoxFlat.new()' not in s
assert 'Panel.new()' not in s
assert 'var picture: TextureRect = TextureRect.new()' not in s
for forbidden in ['_left_arrow', '_right_arrow', '_scroll_by', 'func _arrow(', 'button.add_theme_stylebox_override']:
    assert forbidden not in s, forbidden
# When testing against a complete installation, previous checks must still pass.
if (r / 'education/playtown_catalog.json').is_file():
    assert (r / 'tools/check_v58_1.py').is_file()
print('v58.2 STATIC PASS: direct transparent TextureButtons; touch/mouse swipe; inertia; zero arrows')

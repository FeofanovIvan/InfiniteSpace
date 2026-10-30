#!/usr/bin/env python3
from pathlib import Path
import re
root=Path(__file__).resolve().parent.parent
main=(root/'scripts/Main.gd').read_text()
other=(root/'scripts/OtherSystem.gd').read_text()
assert 'right_button_center - (goal_picker.size.x - NavigationMenuScene.TRIGGER_SIZE * 0.5) * goals_scale' in main
assert 'right_button_center - lower_button_center_local * hud_scale' in main
assert 'right_column_edge - menu_width * goals_scale' not in main
assert 'right_column_edge - ResourceHudScene.HUD_WIDTH * hud_scale' not in main
start=main.index('goal_picker.set_region_destinations(region_id,')
assert '_layout()' in main[start:start+450], 'Menu must be realigned after its width changes'
assert 'var cloud_count: int = 36' in other
assert 'cloud.z_index = 1' in other
assert '_crossroads_world.z_index = 3' in other
assert 'nebula.position = screen_center - nebula.size * 0.5' in other
assert 'nebula.visible = absf(screen_center.x' in other
assert '_crossroads_nebula_data.clear()' in other
assert 'CROSSROADS_NEBULA_SHADER' in other
start=other.index('func _draw() -> void:')
assert 'if str(_region.get("id", "")) == "crossroads":\n\t\treturn' in other[start:]
for undesirable in ['for bolt in range(8):','for shard in range(24):','for burst in range(9):']:
    assert undesirable not in other
# The axis must remain stable even when the number of destination icons changes.
for scale in [0.58,0.9,1.2]:
    joystick_center=575.0
    for width in [190.0,260.0,465.0,546.0]:
        origin=joystick_center-(width-94/2)*scale
        trigger_center=origin+(width-94/2)*scale
        assert abs(trigger_center-joystick_center)<1e-9
print('v53 STATIC PASS: centered HUD, menu reflow, visible world nebulae')

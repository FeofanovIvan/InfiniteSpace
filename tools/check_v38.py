#!/usr/bin/env python3
"""Static regression guard for the minimal v36 -> v38 UI-only change."""
import json, math, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
main=(ROOT/'scripts/Main.gd').read_text()
action=(ROOT/'scripts/ActionButton.gd').read_text()
modal=(ROOT/'scripts/LandingPreview.gd').read_text()
strings=json.loads((ROOT/'locales/strings.json').read_text())
proj=(ROOT/'project.godot').read_text()
assert 'const CONTROL_SCALE_MULTIPLIER: float = 1.10' in main
assert 'base_control_scale * CONTROL_SCALE_MULTIPLIER' in main
for p in ('joystick','action_button','auto_stop_button'):
    assert p+'.scale = Vector2.ONE * control_scale' in main
assert 'var visual_size: float = 184.0 * control_scale' in main
assert 'var margin: float = 18.0 * base_control_scale' in main
assert 'mini_map.scale = Vector2.ONE * map_scale' in main
assert 'goal_picker.scale = Vector2.ONE * goals_scale' in main
assert 'status_hud.scale = Vector2.ONE * hud_scale' in main
assert 'LANDED' not in modal
assert 'landing_preview = LandingPreviewScene.new()' in main
assert 'landing_preview.open_preview(_landing_target_name)' in main
assert 'get_tree().paused = true' in main
assert 'get_tree().paused = false' in main
assert 'get_navigation_bodies()' in main and 'get_map_destinations()' in main
assert 'distance <= radius' in main
assert 'set_action_mode("land" if closest_id != "" else "use")' in main
assert 'set_action_available(closest_id != "")' in main
assert 'get_tree().paused' in main and '_intro_comic_playing' in main
assert 'draw_colored_polygon(hull, tone)' in action
assert 'var ship_center: Vector2 = center + Vector2(0.0, 12.5)' in action
landing_icon = action.split('func _draw_landing(center: Vector2) -> void:', 1)[1]
assert 'draw_colored_polygon(hull, tone)' in landing_icon
assert 'draw_circle(ship_center + Vector2(0, -14)' in landing_icon
assert 'draw_line(' not in landing_icon  # no arrow or landing platform
assert 'signal closed' in modal and 'process_mode = Node.PROCESS_MODE_ALWAYS' in modal
assert 'MobileLocale.safe_rect(view)' in modal
assert 'closed.emit()' in modal
assert 'window/stretch/aspect="expand"' in proj
assert 'window/handheld/orientation=4' in proj
for lang in ('en','ru','fr','de','es','pt_BR'):
    assert strings[lang].get('landing_title') and strings[lang].get('landing_empty'), lang
# Two controls must remain within horizontal safe insets and never overlap.
for width,height, safe_x,safe_r in [(1280,720,18,18),(960,540,18,18),(840,360,45,15),(720,320,56,20),(568,320,40,16),(1024,768,30,30),(2520,1080,110,45)]:
    base=max(.55,min(1.0,width/520.0,height/340.0))
    scale=base*1.10
    outer=184*scale
    margin=18*base
    left=safe_x+margin
    right=width-safe_r-outer-margin
    assert left>=safe_x and right+outer<=width-safe_r
    assert left+outer<right, (width,height, left,right)
print('check_v38: PASS (static controls, landing trigger, placeholder, six locales, simulated insets).')
print('NOTE: Godot F5/parser and mobile touch must be checked on Mac; not tested here.')

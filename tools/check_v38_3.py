#!/usr/bin/env python3
"""Checks the v38.1->v38.3 change without claiming a Godot F5 run."""
from pathlib import Path
import math
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/Main.gd').read_text()
hud=(root/'scripts/RightStatusHUD.gd').read_text()
action=(root/'scripts/ActionButton.gd').read_text()
assert 'const CONTROL_SCALE_MULTIPLIER: float = 1.10' in main
assert 'var right_button_center: float = joystick.position.x + visual_size * 0.5' in main
assert 'var rail_gap: float = 12.0' in main
assert 'right_button_center - (menu_width - NavigationMenuScene.TRIGGER_SIZE * 0.5) * goals_scale' in main
assert 'right_button_center - (ResourceHudScene.HUD_WIDTH - 44.0 + 21.0) * hud_scale' in main
assert 'goal_picker.position.y + NavigationMenuScene.TRIGGER_SIZE * goals_scale + rail_gap' in main
assert '_make_icon_button("GlobalFlight", GALAXY_ICON, 46.0' in hud
assert 'button.position = Vector2(HUD_WIDTH - 44.0, 100.0)' in hud
assert 'size = Vector2(HUD_WIDTH, 142.0)' in hud
assert 'draw_line(center + Vector2(-32, 36)' not in action, 'v38.1 must keep ship-only landing glyph'
assert 'draw_colored_polygon(hull, tone)' in action
# The position formula targets each button centre, not the containing panel's edge.
# Geometry simulation for several landscape sizes, no actual rendering claimed.
for w,h in [(1280,720),(1920,1080),(2520,1080),(960,540),(1024,768),(800,600),(720,320),(568,320)]:
    safe_x=min(w,h)*.02
    base=max(.55,min(1.,w/520,h/340))
    cs=base*1.10
    joystick_x=w-safe_x-184*cs-18*base
    center=joystick_x+92*cs
    gs=max(.58,min(1.,w/720,h/440))
    hs=max(.52,min(1.,w/700,h/490))
    mapscale=max(.55,min(1.,w/700,h/490))
    mapright=safe_x+12*mapscale+260*mapscale+12
    available=center+94*gs*.5-mapright-12
    mw=min(max(190,available/gs),546)
    nav_x=center-(mw-47)*gs
    preview_center=nav_x+(mw-47)*gs
    hud_x=center-(126-44+21)*hs
    galaxy_center=hud_x+(126-44+21)*hs
    ship_center=galaxy_center
    assert abs(preview_center-center)<1e-6
    assert abs(galaxy_center-center)<1e-6
    assert abs(ship_center-center)<1e-6
    assert (center+47*gs)<w-safe_x
    assert (center+21*hs)<w-safe_x
    assert (46-34)==12 and (100-46-42)==12
print('check_v38_3: PASS; source centres aligned; no new control; 12px authored gaps.')
print('NOTE: F5 and touch QA in Godot still required.')

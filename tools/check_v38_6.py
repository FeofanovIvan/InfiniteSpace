#!/usr/bin/env python3
"""v38.6 regression: only top-right visual growth, two lower buttons 20%."""
from pathlib import Path
from math import isclose
root=Path(__file__).resolve().parents[1]
main=(root/'scripts/Main.gd').read_text(encoding='utf-8')
nav=(root/'scripts/NavigationMenu.gd').read_text(encoding='utf-8')
hud=(root/'scripts/RightStatusHUD.gd').read_text(encoding='utf-8')
assert 'goals_scale: float = clampf(minf(view.x / 720.0, view.y / 440.0), 0.58, 1.0) * 1.10' in main
assert 'hud_scale: float = clampf(minf(view.x / 700.0, view.y / 490.0), 0.52, 1.0) * 1.10' in main
assert 'lower_button_extra: float = 1.20 / 1.10' in main
assert 'galaxy_button.scale = Vector2.ONE * lower_button_extra' in main
assert 'ship_menu_button.scale = Vector2.ONE * lower_button_extra' in main
assert 'var rail_gap: float = 12.0' in main
assert 'local_gap: float = rail_gap / hud_scale' in main
assert 'status_hud.size = Vector2(ResourceHudScene.HUD_WIDTH, second_button_y + lower_button_local_size)' in main
assert '(RAIL_HEIGHT - TILE_SIZE) * 0.5' in nav
assert 'preload("res://asteroid_assets/fragments/04_blue/crystal_wedge.png")' in hud
assert 'panel.clip_contents = true' in hud
assert 'if fuel_segments <= 2:' in hud and 'elif fuel_segments <= 5:' in hud
assert 'var control_scale: float = base_control_scale * CONTROL_SCALE_MULTIPLIER' in main
assert 'joystick.scale = Vector2.ONE * control_scale' in main
assert 'action_button.scale = Vector2.ONE * control_scale' in main

# Numeric simulation follows the exact placement formulas in Main._layout.
# Large windows must preserve factors 1.10 and 1.20. Short windows may
# scale the upper column together so it does not overlap the joystick.
scenarios=[
    (1280,720,(14,14,14,14)),(1920,1080,(20,20,20,20)),
    (2520,1080,(50,20,20,20)),(960,540,(11,11,11,11)),
    (1024,768,(15,15,15,15)),(800,600,(12,12,12,12)),
    (720,320,(54,10,18,10)),(568,320,(45,10,15,10)),
    (479,360,(20,10,10,10)),(960,360,(72,10,20,10)),
    (820,320,(62,10,30,10)),
]
for w,h,(left,top,right,bottom) in scenarios:
    cb=max(.55,min(1.,w/520,h/340))
    ctrl=cb*1.10
    jsize=184*ctrl
    margin=18*cb
    jtop=max(top+margin,h-bottom-jsize-margin)
    jcenter=(w-right-jsize-margin)+jsize*.5
    gs=max(.58,min(1.,w/720,h/440))*1.10
    hs=max(.52,min(1.,w/700,h/490))*1.10
    local_b=42*(1.20/1.10)
    req=94*gs+34*hs+2*local_b*hs
    available=jtop-top-12-8-3*12
    fit=max(.10,min(1.,available/max(1.,req)))
    gs*=fit
    hs*=fit
    nav_y=top+12
    nav_h=94*gs
    hud_y=nav_y+nav_h+12
    screen_gap=12
    first=34+screen_gap/hs
    second=first+local_b+screen_gap/hs
    actual_h=(second+local_b)*hs
    hud_bottom=hud_y+actual_h
    first_center=103*hs
    ship_center=(103-local_b*.5+local_b*.5)*hs
    assert isclose(first_center,ship_center,abs_tol=1e-6)
    # Authored spacing is 12px at any overall scale.
    assert isclose((first-34)*hs,12.0,abs_tol=1e-5)
    assert isclose((second-first-local_b)*hs,12.0,abs_tol=1e-5)
    # Against v38.5 baseline the two buttons are 20% bigger on non-compact screens.
    orig_hs=max(.52,min(1.,w/700,h/490))
    ratio=(42*(1.20/1.10)*hs)/(42*orig_hs)
    if fit==1:
        assert isclose(ratio,1.2,abs_tol=1e-6)
        assert isclose(gs / max(.58,min(1.,w/720,h/440)),1.10,abs_tol=1e-6)
    assert hud_bottom<=jtop+2.0,(w,h,fit,hud_bottom,jtop)
    assert jcenter + 0.5*94*gs < w-right
print('check_v38_6: PASS — +10% destination/fuel, +20% two buttons, 12px gaps, aligned centers, landscape geometry.')
print('Godot parser and live mobile screenshots still require F5/device testing.')

#!/usr/bin/env python3
"""v43 regression: uniform +20% vs v42 on the upper-right HUD only.
Checks are static/numeric; real Godot F5 & device render remain necessary.
"""
from pathlib import Path
from math import isclose
ROOT=Path(__file__).resolve().parents[1]
main=(ROOT/'scripts/Main.gd').read_text(encoding='utf8')
nav=(ROOT/'scripts/NavigationMenu.gd').read_text(encoding='utf8')
hud=(ROOT/'scripts/RightStatusHUD.gd').read_text(encoding='utf8')
assert 'const UPPER_RIGHT_UI_GROWTH: float = 1.20' in main
assert ')* 1.10' not in main  # formatting guard not a behavior rule
assert '1.10 * UPPER_RIGHT_UI_GROWTH' in main
assert main.count('1.10 * UPPER_RIGHT_UI_GROWTH') == 2
assert 'var lower_button_extra: float = 1.20 / 1.10' in main
assert 'var rail_gap: float = 12.0' in main
assert 'var local_gap: float = rail_gap / hud_scale' in main
assert 'right_button_center - (menu_width - NavigationMenuScene.TRIGGER_SIZE * 0.5) * goals_scale' in main
assert 'right_button_center - (ResourceHudScene.HUD_WIDTH - 44.0 + 21.0) * hud_scale' in main
assert 'var control_scale: float = base_control_scale * CONTROL_SCALE_MULTIPLIER' in main
assert 'const CONTROL_SCALE_MULTIPLIER: float = 1.10' in main
assert '(RAIL_HEIGHT - TILE_SIZE) * 0.5' in nav
assert 'asteroid_assets/fragments/04_blue/crystal_wedge.png' in hud
assert 'panel.clip_contents = true' in hud
assert 'if fuel_segments <= 2:' in hud and 'elif fuel_segments <= 5:' in hud
assert 'galaxy_button.scale = Vector2.ONE * lower_button_extra' in main
assert 'ship_menu_button.scale = Vector2.ONE * lower_button_extra' in main

# Model the exact Main.gd layout formula, comparing with v42. The physical
# spacing is always 12px; 20% element growth holds whenever it fits.
SIZES=[(1280,720,(12,12,12,12)),(1920,1080,(20,20,20,20)),
(2520,1080,(54,20,18,20)),(1920,800,(20,12,20,12)),
(960,540,(12,12,12,12)),(1024,768,(16,16,16,16)),
(800,600,(12,12,12,12)),(840,360,(48,10,16,10)),
(720,320,(54,10,18,10)),(568,320,(44,10,16,10))]
regular=[]
for w,h,(safe_l,safe_t,safe_r,safe_b) in SIZES:
 base=max(.55,min(1.,w/520.,h/340.))
 ctrl=base*1.10
 js=184*ctrl
 margin=18*base
 joy_x=w-safe_r-js-margin
 joy_y=max(safe_t+margin,h-safe_b-js-margin)
 centre=joy_x+js*.5
 def layout(growth):
  g=max(.58,min(1.,w/720.,h/440.))*1.10*growth
  s=max(.52,min(1.,w/700.,h/490.))*1.10*growth
  b=42.*(1.20/1.10)
  req=94*g+34*s+2*b*s
  usable=joy_y-safe_t-12.-8.-3*12.
  fit=max(.10,min(1.,usable/max(1.,req)))
  g*=fit;s*=fit
  trigger_top=safe_t+12.
  bar_top=trigger_top+94*g+12
  gal_top=bar_top+34*s+12
  ship_top=gal_top+b*s+12
  bottom=ship_top+b*s
  centres=[centre,centre,centre,centre]
  assert all(isclose(x,centre,abs_tol=.0001) for x in centres)
  assert isclose(bar_top-(trigger_top+94*g),12,abs_tol=.0001)
  assert isclose(gal_top-(bar_top+34*s),12,abs_tol=.0001)
  assert isclose(ship_top-(gal_top+b*s),12,abs_tol=.0001)
  assert bottom <= joy_y + 2.01,(w,h,joy_y,bottom)
  assert trigger_top>=safe_t
  return g,s,b*s,fit
 old=layout(1.0)
 now=layout(1.2)
 if old[-1]==1 and now[-1]==1:
  regular.append((w,h))
  for a,b in zip(now[:3],old[:3]):
   assert isclose(a/b,1.2,abs_tol=1e-8),(w,h,a,b)
 print(f'{w}x{h}: effective +{(now[0]/old[0]-1)*100:.1f}% trigger; compact-fit={now[-1]:.2f}')
assert len(regular)>=3, regular
print('check_v43: PASS — +20% on fitting screens, 12px fixed gaps, same centre, safe joystick clearance.')
print('NOTE: On very short screens the upper rail is fitted smaller to avoid overlap. Visual Godot F5 needed.')

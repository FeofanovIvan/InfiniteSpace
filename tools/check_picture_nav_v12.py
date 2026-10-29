#!/usr/bin/env python3
"""Static checks for v0.12 one-row destination bar (not Godot runtime)."""
from pathlib import Path
import re, math
root=Path(__file__).resolve().parent.parent
nav=(root/'scripts/NavigationMenu.gd').read_text(encoding='utf-8')
main=(root/'scripts/Main.gd').read_text(encoding='utf-8')
failures=[]
def check(cond, what):
    if not cond: failures.append(what)
check('HBoxContainer.new()' in nav, 'Missing horizontal single row')
check('GridContainer' not in nav and 'PictureTargets3x3' not in nav,'Old square grid still present')
check('ExpandableDestinationsToLeft' in nav and '_trigger.position.x - RAIL_GAP - _shown_width' in nav,'Rail not anchored to trigger while opening left')
check('ScrollContainer.new()' in nav and 'SCROLL_MODE_AUTO' in nav,'No scroll for narrow touch screens')
check('target_selected.emit(id)' in nav and 'tile.pressed.connect(_choose.bind(id))' in nav,'Picture tap does not select target')
check('goal_picker.set_available_width(menu_width)' in main,'Main layout does not adapt bar width')
check('goal_picker.set_autopilot_status(true, target_id)' in main and '_on_auto_stop_pressed()' in main,'Autopilot / STOP missing')
check('map_right:' in main and '260.0 * map_scale' in main,'Mini-map is not accounted for in menu layout')
check('"EarthStation"' in nav,'Station missing')
check(len(re.findall(r'"(?:Mercury|Venus|Earth|Mars|Jupiter|Saturn|Uranus|Neptune|EarthStation)": preload', nav)) == 6,'Missing planet icon preloads')
for p in root.rglob('*.gd'):
    t=p.read_text(encoding='utf-8')
    check(not(any(x.startswith('\t') for x in t.splitlines()) and any(x.startswith(' ') for x in t.splitlines())),f'Mixed GDScript indentation: {p.relative_to(root)}')
    for res in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)',t):
        check((root/res).exists(),f'Missing resource {res}')
# UI rects: right edge of the trigger always remains at the screen margin;
# left edge of the scroll strip never overlaps the mini-map in representative screens.
for w,h in [(1280,720),(960,540),(800,480),(720,400),(720,1280),(390,844)]:
    map_scale=max(.55,min(1.,w/700.,h/490.))
    goals_scale=max(.58,min(1.,w/720.,h/440.))
    map_right=18*map_scale+260*map_scale+12
    available_px=w-map_right-16
    available_units=max(190.,available_px/goals_scale)
    menu_width=min(762.,available_units)
    right=w-16
    left=right-goals_scale*menu_width
    mini_right=map_right-12
    check(left>=mini_right-1.0 or available_units ==190.,f'Collision with mini-map on {w}x{h}: {left:.1f} < {mini_right:.1f}')
    check(right <= w and left >= -0.01,f'Menu offscreen: {w}x{h}')
if failures:
    print('FAIL:', *failures,sep='\n- ')
    raise SystemExit(1)
print('PASS: one left-expanding horizontal row; 5 destinations + station; touch scrolling; mobile geometry; autopilot; no mixed tabs')

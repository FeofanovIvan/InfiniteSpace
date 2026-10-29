#!/usr/bin/env python3
"""Static geometry regression tests for v0.8; requires only Python 3."""
from pathlib import Path
import math
import re

root=Path(__file__).resolve().parents[1]
solar=(root/'scripts/SolarSystem.gd').read_text()
mini=(root/'scripts/MiniMap.gd').read_text()


def scalar(name):
    m=re.search(r'const '+name+r': float = (\d+\.\d+)',solar)
    assert m, f'Missing {name}'
    return float(m.group(1))


def mini_scalar(name):
    m=re.search(r'const '+name+r': float = (\d+\.\d+)',mini)
    assert m, f'Missing {name}'
    return float(m.group(1))

orbits=[('Sun',0.0,scalar('SUN_DIAMETER'))]
for name in ('Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune'):
    if name=='Earth':
        orbits.append((name,scalar('ORBIT_RADIUS'),scalar('EARTH_DIAMETER')))
        continue
    match=re.search(r'\{"name": "'+name+r'", "orbit": ([^,]+), "period": [^,]+, "phase": [^,]+, "size": ([^,]+)',solar)
    assert match, f'Missing data: {name}'
    orbit=scalar('OUTER_ORBIT_RADIUS') if match.group(1)=='OUTER_ORBIT_RADIUS' else float(match.group(1))
    orbits.append((name,orbit,float(match.group(2))))
assert len(orbits)==9,orbits
ordered=sorted(orbits,key=lambda x:x[1])
for inner,outer in zip(ordered,ordered[1:]):
    gap=outer[1]-inner[1]-(inner[2]+outer[2])/2
    assert gap > 10, f'overlap risk: {inner[0]}, {outer[0]}: {gap}'
    print(f'Radial gap {inner[0]:>7}–{outer[0]:<7}: {gap:.1f} px')
for name,orbit,diam in ordered[1:]:
    assert 108 <= diam <= 236, f'{name} outside v22 child-friendly size range'

m=re.search(r'const PANEL: Vector2 = Vector2\((\d+\.\d+), (\d+\.\d+)\)',mini)
assert m and m.group(1)==m.group(2)
side=float(m.group(1))
center=130
radius=mini_scalar('MAP_RADIUS')
assert abs(2*radius-side)<=8
assert '_draw_clipped_view_edge' in mini, 'True camera rectangle clipping missing'
assert '_camera_view_world_size' in mini, 'Camera viewport extent missing'
outer_radius=scalar('OUTER_ORBIT_RADIUS')
scale=mini_scalar('DEFAULT_UNITS_PER_PIXEL')
assert outer_radius/scale < radius-10, 'Neptune not fully visible at startup'
assert 'tracking_mode_changed' in mini
assert '_map_position.advance(delta_to_target * alpha)' in mini
assert scalar('MOON_DIAMETER') > 20 and scalar('MOON_ORBIT_RADIUS') > scalar('EARTH_DIAMETER') * 0.5
print('PASS: 8 enlarged planets and Moon, safe orbit spacing, square panel / round map / viewport frame, navigation-follow code')

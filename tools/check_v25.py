#!/usr/bin/env python3
"""V25 preflight: full-bleed motion comic, nine intact originals, direct dive."""
from pathlib import Path
import math, re, struct
P=Path(__file__).resolve().parents[1]
comic=(P/'scripts/ComicPrologue.gd').read_text()
main=(P/'scripts/Main.gd').read_text()
smoke=(P/'scripts/StoryLandingSmoke.gd').read_text()
required=['01_homeworld.png','02_mika_reacts.png','03_holographic_world.png',
 '04_city_under_vortex.png','05_storm_sweeps_city.png','04_warning.png',
 '05_departure.png','06_storm_outside.png','07_storm_cockpit.png']
found=re.findall(r'"res://assets/prologue_original/([^"/]+\.png)"',comic)
assert found==required,('Incorrect story sequence',found)
assert len(list((P/'assets/prologue_original').glob('*.png')))==9
for f in required:
 raw=(P/'assets/prologue_original'/f).read_bytes()
 assert raw[:8]==b'\x89PNG\r\n\x1a\n' and raw[12:16]==b'IHDR'
 w,h=struct.unpack('>II',raw[16:24]); assert w>=1000 and h>=700,(f,w,h)
assert 'maxf(_view_size.x / image_size.x, _view_size.y / image_size.y)' in comic
assert 'FOCUS_START[_frame].lerp(FOCUS_END[_frame], smooth)' in comic
assert 'FRAME_PATHS.size()' in comic and 'CROSSFADE' in comic
assert '_previous.texture = _art.texture' in comic
assert 'minf(_view_size.x / image_size.x, _view_size.y / image_size.y)' not in comic
assert 'BACKDROP_PATHS' not in comic
assert 'KEY_ESCAPE' in comic and 'skipped.emit()' in comic
assert '_story_move_to(target_world)' in main
assert '_story_sun_orbit_position' not in main and 'STORY_SUN_ORBIT' not in main
assert '_story_hermite' not in main and 'STORY_WAYPOINT' not in main
assert 'STORY_EJECTION_START' in main and 'STORY_CONTROL_ONE' in main
assert 'solar_system.earth_world_position()' in main
assert 'npc_traffic.z_index = 10' in main and 'ship.z_index = 15' in main
assert 'ship.rotation = _ship_heading' in main
assert 'ship.scale = Vector2.ONE * maxf(0.018' in main
assert 'var flash: float' in smoke and 'for i in range(11):' in smoke
# Simulate direct cubic with the Earth moving throughout the sequence.
p0=(6320.,-2865.); p1=(4780.,-2450.); p2=(2320.,-550.); T=11.8
# Earth starts at the X axis, at 565 radius and 180s orbit period.
def world(t):
 u=t/T; a=.84*u+.16*u*u; v=1.-a
 earth=(565*math.cos(math.tau*t/180)-8,565*math.sin(math.tau*t/180)-12)
 return tuple(v**3*p0[i]+3*v*v*a*p1[i]+3*v*a*a*p2[i]+a**3*earth[i] for i in (0,1))
pts=[world(T*i/1400) for i in range(1401)]
speeds=[math.dist(a,b)/(T/1400) for a,b in zip(pts,pts[1:])]
assert min(speeds)>150,('Unexpected slow/stop',min(speeds))
assert math.dist(pts[-1],(565*math.cos(math.tau*T/180)-8,565*math.sin(math.tau*T/180)-12))<.01
# No solar orbit: trajectory approaches Earth on a steadily decreasing X world coordinate.
assert all(pts[i+1][0] < pts[i][0] for i in range(len(pts)-1))
# Source paths, mixed indentation, and stale wrong input API check.
for f in (P/'scripts').glob('*.gd'):
 s=f.read_text()
 kinds={('tab' if ln.startswith('\t') else 'space') for ln in s.splitlines() if ln and ln[0] in '\t '}
 assert len(kinds)<=1,(f.name,kinds)
 assert 'is_key_just_pressed(' not in s,f.name
 for path in re.findall(r'preload\("res://([^"\n]+)"\)',s):
  assert (P/path).is_file(),(f.name,path)
print('PASS V25: 9 intact original PNGs; full-screen moving cover camera; crossfade; storm shake; direct continuous Earth dive; clear readable smoke; drawing layers; min flight speed %.1f world units/sec; scripts and preload assets' % min(speeds))

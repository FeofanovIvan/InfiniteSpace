#!/usr/bin/env python3
"""Dependency-free structural validation for atlas/warp prototype v26."""
import json,re,sys,zipfile
from pathlib import Path
P=Path(__file__).resolve().parents[1]
data=json.loads((P/'atlas/world_atlas.json').read_text(encoding='utf-8'))
systems=data['systems']
assert len(systems)==7
assert [s['id'] for s in systems]==['mw','lmc','smc','ngc6822','m31','m33','crossroads']
assert sum(len(s['planets']) for s in systems)==48
assert sum(len(p['moons']) for s in systems for p in s['planets'])==64
assert len([s for s in systems if s.get('station')])==6
assert systems[-1]['status']=='marker_only'
all_ids=[p['id'] for s in systems for p in s['planets']]
assert len(set(all_ids))==48
assert all(p['landing'] in ['landing','orbit'] for s in systems for p in s['planets'])
assert all(len(s['planets'])==8 for s in systems[:6])
assert len(list((P/'assets/atlas/planets').glob('*.png')))==40
assert len(list((P/'assets/atlas/suns').glob('*.png')))==7
for s in systems[1:6]:
 for p in s['planets']:
  file=P/p['visual_asset'].removeprefix('res://')
  assert file.is_file(),file
for i in range(1,9):
 assert (P/f'lmc_planets/planets/lmc_p{i:02d}.tscn').is_file()
 assert (P/f'lmc_planets/textures/lmc_p{i:02d}_surface.jpg').is_file()
for script in ['scripts/AtlasSystem.gd','scripts/OtherSystem.gd','scripts/AtlasLandmark.gd','scripts/GalacticMap.gd','scripts/WarpOverlay.gd','scripts/Main.gd','scripts/NavigationMenu.gd','scripts/MiniMap.gd']:
 assert (P/script).is_file()
 text=(P/script).read_text()
 for lineno,line in enumerate(text.splitlines(),1):
  assert not ('\t' in line[:len(line)-len(line.lstrip())] and ' ' in line[:len(line)-len(line.lstrip())]),(script,lineno)
 for path in re.findall(r'preload\("res://([^"]+)"\)',text):
  assert (P/path).exists(),(script,path)
main=(P/'scripts/Main.gd').read_text()
assert 'solar_system.set_region(region_id)' in main
assert 'if _warp_active:' in main
assert 'galactic_map.travel_requested.connect(' in main
assert '_warp_overlay.end_warp()' in main
assert 'func _advance_warp(delta: float)' in main
assert 'var _warp_active: bool = false' in main
nav=(P/'scripts/NavigationMenu.gd').read_text()
assert 'set_region_destinations' in nav
world=(P/'scripts/OtherSystem.gd').read_text()
assert 'LMC_SCENES' in world and '_moons.append' in world and '_landmarks.append' in world
# Check PNG headers without Pillow (works on a default macOS Python install).
def png_size(path):
 with open(path,'rb') as f:head=f.read(24)
 assert head[:8]==b'\x89PNG\r\n\x1a\n',path
 return int.from_bytes(head[16:20],'big'),int.from_bytes(head[20:24],'big')
for path in list((P/'assets/atlas/planets').glob('*.png'))+list((P/'assets/atlas/suns').glob('*.png')):
 assert min(png_size(path)) >= 128
print('PASS v26: 7 atlas locations, 48 planets, 64 listed moons, 6 station markers')
print('PASS v26: 40 planet thumbnails, 7 sun icons, 8 LMC original scenes')
print('PASS v26: warp state, map signals, resource references and GDScript indentation')
print('NOTE: Godot F5 + renderer/GDScript parser tests must still be performed on device.')

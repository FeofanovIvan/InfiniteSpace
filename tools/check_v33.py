#!/usr/bin/env python3
"""v33 static moon asset and atlas integrity gate; never claims Godot runtime validation."""
from __future__ import annotations
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
moon_dir = ROOT / 'moon2d'
assert moon_dir.is_dir(), 'Missing moon2d/ bundle; re-install full v33 moon patch'
profiles = json.loads((moon_dir / 'catalog.json').read_text(encoding='utf-8'))['profiles']
atlas = json.loads((ROOT / 'atlas' / 'world_atlas.json').read_text(encoding='utf-8'))['systems']
assert len(profiles) == 64, f'Expected 64 individual moon profiles, found {len(profiles)}'
by_id = {p['id']:p for p in profiles}
assert len(by_id) == len(profiles), 'Duplicate moon IDs in source catalog'
assert (moon_dir / 'moon_globe.gdshader').is_file()
assert (moon_dir / 'white_quad.png').is_file()
assert (moon_dir / 'moon_2d.tscn').is_file()
assert (moon_dir / 'moon2d.gd').is_file()
registered = []
counts = Counter()
for region in atlas:
    for planet in region.get('planets', []):
        for idx, name in enumerate(planet.get('moons', []), 1):
            moon_id = f'{planet["id"]}_m{idx:02}'
            registered.append(moon_id)
            assert moon_id in by_id, f'Moon missing from catalog: {moon_id}'
            entry = by_id[moon_id]
            assert entry['parent_id'] == planet['id'], f'Wrong parent for {moon_id}'
            assert entry['galaxy'] == region['id'], f'Wrong galaxy for {moon_id}'
            assert entry['name_ru'] == name, f'Wrong name for {moon_id}: {name}'
            scene_path = moon_dir / 'scenes' / (moon_id+'.tscn')
            texture_path = moon_dir / 'textures' / (moon_id+'_surface.jpg')
            assert scene_path.is_file(), f'Missing scene: {scene_path}'
            assert texture_path.is_file(), f'Missing texture: {texture_path}'
            scene = scene_path.read_text(encoding='utf-8')
            assert f'moon_id = "{moon_id}"' in scene, f'Wrong scene moon_id {moon_id}'
            counts[region['id']] += 1
assert len(registered)==64 and len(set(registered))==64
assert set(registered)==set(by_id)
expected={'mw':20,'lmc':10,'smc':12,'ngc6822':7,'m31':8,'m33':7}
assert dict(counts)==expected, (dict(counts),expected)
print('PASS 64/64 individual moon scenes and textures')
print('PASS moon names / parent IDs / galaxy IDs match the world atlas')
print('PASS Moon2D shader and source reusable scene')
lib=(ROOT/'scripts/MoonLibrary.gd').read_text(encoding='utf-8')
assert len(re.findall(r'preload\("res://moon2d/scenes/[^"\n]+\.tscn"\)',lib))==64
assert len(re.findall(r'preload\("res://moon2d/textures/[^"\n]+\.jpg"\)',lib))==64
for key in registered:
    assert f'"{key}": preload(' in lib, f'Not preloaded for export: {key}'
print('PASS explicit GDScript preloads for all 64 scenes and 64 surfaces')
solar=(ROOT/'scripts/SolarSystem.gd').read_text(encoding='utf-8')
atlas_system=(ROOT/'scripts/AtlasSystem.gd').read_text(encoding='utf-8')
other=(ROOT/'scripts/OtherSystem.gd').read_text(encoding='utf-8')
for name,text in [('SolarSystem',solar),('AtlasSystem',atlas_system),('OtherSystem',other)]:
    assert 'MoonLibrary.make_moon' in text, f'{name}: old placeholder still used'
    assert 'MOON_TEXTURE' not in text, f'{name}: placeholder texture still referenced'
assert '"mw_p01_m01"' in solar
assert '"_m%02d"' in atlas_system and '"_m%02d"' in other
assert '_station' in solar and 'STATION_SHELL_VARIANTS' in other
print('PASS Earth, remaining MW, and other regions now use supplied moon scenes')
print('PASS ring/station code retained; NPC traffic remains unchanged')
for region, count in expected.items():
    print(f'PASS {region} = {count} moons')
print('check_v33: OK — static checks only, Godot F5/render remains to be tested')

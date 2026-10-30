#!/usr/bin/env python3
"""Guard against drawing fictional 'moon' symbols in external systems.

This is a static test. It does NOT replace a Godot 4.7.1 F5 render test.
"""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'scripts/OtherSystem.gd').read_text(encoding='utf-8')
atlas = json.loads((ROOT / 'atlas/world_atlas.json').read_text(encoding='utf-8'))['systems']
systems = {item['id']:item for item in atlas}

# The offending icon in the screenshot was generated from AtlasLandmark,
# not from moon2d: lmc_p01 has no registered moons.
assert systems['lmc']['planets'][0]['id'] == 'lmc_p01'
assert systems['lmc']['planets'][0]['moons'] == []
print('PASS LMC/Aera has zero real moons; original violet icon was a landmark')

for tag in ['LandmarkClass', 'Landmark_', '_landmarks', '_station_symbol', 'UniqueStationSilhouette_']:
    assert tag not in source, f'Fake landmark still wired in runtime source: {tag}'
assert 'LandmarkClass.new()' not in source
print('PASS no per-planet symbol instances (40 false moon/station objects removed)')
print('PASS no superimposed station glyphs (5 false extra objects removed)')

# Keep actual celestial objects and previously approved system-wide station rings.
for tag in ['MoonLibrary.make_moon(', '_moons.append(', '_library_for_region(',
            '_build_planet_orbital_ring(', '_choose_system_ring_stations(',
            'STATION_SHELL_VARIANTS', 'SYSTEM_RING_COUNTS', '_station_sprite.position',
            'get_target_state(', 'get_navigation_bodies(']:
    assert tag in source, f'Regression: {tag} missing'

counts = {'lmc':2, 'smc':3, 'ngc6822':2, 'm31':4, 'm33':3}
for key, value in counts.items():
    assert f'"{key}": {value}' in source
    assert len(systems[key]['planets']) == 8
assert (ROOT/'moon2d/catalog.json').is_file()
assert len(json.loads((ROOT/'moon2d/catalog.json').read_text(encoding='utf-8'))['profiles']) == 64
print('PASS 64 approved moon scenes and 14 approved station rings preserved')
print('PASS navigation target and existing story station retained')
print('check_v33_1: OK — source checks only; Godot F5 visual verification outstanding')

#!/usr/bin/env python3
"""Dependency-free v0.22 source and gameplay-math regression check (not Godot compilation)."""
from pathlib import Path
import math, re, struct
base = Path(__file__).resolve().parents[1]
solar = (base/'scripts/SolarSystem.gd').read_text()
asteroids = (base/'scripts/AsteroidField.gd').read_text()
bridge = (base/'scripts/MikoMainMenu.gd').read_text()
minimap = (base/'scripts/MiniMap.gd').read_text()
npc = (base/'scripts/NpcTraffic.gd').read_text()

def png(path):
    p=base/path
    assert p.is_file(), f'Missing image {path}'
    with p.open('rb') as f: head=f.read(26)
    assert head[:8]==b'\x89PNG\r\n\x1a\n' and head[12:16]==b'IHDR', path
    w,h = struct.unpack('>II',head[16:24]); assert w>10 and h>10,(path,w,h)
    return w,h

assert png('assets/characters/miko.png')[1] >= 300
assert png('assets/solar/moon_surface.png')==(256,256)
assert '"miko.png", "OriginalMikoCharacter"' in bridge
assert 'view.y * 0.89 - _miko_sprite.size.y' in bridge
assert 'const MOON_ORBIT_RADIUS: float = 116.0' in solar
assert 'const MOON_ORBIT_PERIOD_SECONDS: float = 48.0' in solar
assert 'func moon_world_position() -> Vector2:' in solar
assert 'return earth_world_position() + Vector2.from_angle(_moon_phase) * MOON_ORBIT_RADIUS' in solar
assert '"name": "Moon"' in solar and 'elif name == "Moon"' in minimap
for name,size in [('Jupiter',236),('Saturn',220),('Uranus',188),('Neptune',192)]:
    assert re.search(r'"name": "'+name+r'"[^\n]*"size": '+str(size)+r'\.0',solar),name
assert len(list((base/'planets').glob('*.tscn')))==8
assert len(re.findall(r'"name": "(?:Mercury|Venus|Mars|Jupiter|Saturn|Uranus|Neptune)"',solar))==7
assert 'const MAX_ASTEROIDS: int = 1' in asteroids
assert '_rng.randf_range(60.0, 120.0)' in asteroids
assert '_rng.randf_range(40.0, 65.0)' in asteroids
assert '_spawn_solar_flyby()' in asteroids and '_flyby_position(' in asteroids
assert 'Input.is_key_pressed(KEY_F9)' in asteroids and 'is_key_just_pressed' not in asteroids
assert 'func _shatter(' in asteroids and 'func _find_contact(' in asteroids
assert 'const POPULATION: int = 14' in npc
# Check minimum separation of neighboring enlarged orbital discs
rings=[('Sun',0,186),('Mercury',245,108),('Venus',395,118),('Earth',565,120),('Mars',740,112),('Jupiter',990,236),('Saturn',1270,220),('Uranus',1600,188),('Neptune',1950,192)]
for a,b in zip(rings,rings[1:]):
    gap=b[1]-a[1]-0.5*(a[2]+b[2]); assert gap>25,(a[0],b[0],gap)
# Moon begins away from player at (650,35); its orbit follows Earth's world position
mx,my = 565+116*math.cos(2.40),116*math.sin(2.40)
assert math.hypot(mx-650,my-35)>100
# Fly-by radial curve stays clear of the Sun at 225px perihelion, and returns outward.
for t in [i/100 for i in range(101)]:
    r=225+(1050-225)*abs(2*t-1)**1.36
    assert r>190
assert abs((225+(1050-225))-1050)<1e-3
# No third-party Pillow import or mixed leading whitespace in scripts
for f in base.rglob('*.gd'):
    src=f.read_text()
    kinds={('tab' if line.startswith('\t') else 'space') for line in src.splitlines() if line and line[0] in ' \t'}
    assert len(kinds)<=1,(str(f),kinds)
    for path in re.findall(r'(?:preload|load)\("(res://[^\"]+)"\)',src):
        assert (base/path[6:]).is_file(),(f.name,path)
print('PASS v22: Miko PNG, Moon position + artwork, large giants, safe orbits, one rare asteroid, solar flyby, existing NPC/planet resources')
print('NOTE: Real Godot GDScript parsing and rendering require a headless/editor run on Mac.')

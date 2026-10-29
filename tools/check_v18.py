#!/usr/bin/env python3
"""Static integrity and regression checks. Does not replace Godot execution."""
from pathlib import Path
import struct
import re
def png_info(path: Path) -> tuple[int, int, str]:
    """Read the PNG header using the Python standard library (no Pillow required)."""
    with path.open("rb") as f:
        header = f.read(26)
    assert len(header) == 26 and header[:8] == b"\x89PNG\r\n\x1a\n", path
    assert header[12:16] == b"IHDR", path
    width, height = struct.unpack(">II", header[16:24])
    color_type = header[25]
    return width, height, "RGBA" if color_type == 6 else f"PNG color type {color_type}"

root=Path(__file__).resolve().parents[1]
main=(root/'scripts/Main.gd').read_text()
npc=(root/'scripts/NpcTraffic.gd').read_text()
field=(root/'scripts/AsteroidField.gd').read_text()
hud=(root/'scripts/RightStatusHUD.gd').read_text()
assert 'const POPULATION: int = 14' in npc
assert sum(map(int, re.findall(r'"weight":(\d+)',npc)))==100
assert 'func try_asteroid_impact(' in npc
assert 'const HUD_WIDTH: float = 126.0' in hud
assert 'BlueCrystal_NoDigits' in hud
assert 'MikoMainMenu' in hud
for key in ['set_camera_address(', 'set_ship_world(', 'asteroid_impact.connect(', 'asteroid_fragments']:
    assert key in main,key
for key in ['"Player"', '"Sun"','"EarthStation"','try_asteroid_impact(', '"Asteroid"','_shatter(']:
    assert key in field,key
for i,name in ((1,'01_gray_cratered'),(3,'03_dark_fissured'),(4,'04_blue_mineral'),(6,'06_violet_mineral')):
    p=root/'asteroid_assets/original'/f'{name}.png'
    assert p.is_file()
    assert png_info(p)==(512,512,'RGBA'),p
for folder in ['01_gray','03_ember','04_blue','06_violet']:
    files=list((root/'asteroid_assets/fragments'/folder).glob('*.png'))
    assert len(files)==9,(folder,len(files))
    for p in files:
        assert png_info(p)==(320,320,'RGBA'),p
p=root/'blackhole2d/textures/black_hole_cinematic.png'
assert png_info(p) in [(768,768,'RGBA'),(1152,570,'RGBA')],p  # v20 realistic isolated disc
assert 'black_hole_cinematic.gdshader' in (root/'blackhole2d/scripts/black_hole_2d.gd').read_text()
for file in root.rglob('*.gd'):
    txt=file.read_text()
    leads={('tab' if l.startswith('\t') else 'space') for l in txt.splitlines() if l[:1] in ('\t',' ')}
    assert len(leads)<=1, (file.name,leads)
    assert txt.count('(')>=txt.count(')')-2,file # very coarse syntax screen
for name in ['Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune']:
    assert (root/'planets'/f'{name.lower()}.tscn').exists()
print('PASS v18 resources / v19 config: 14 NPC, 4 asteroid sources, 36 debris textures, 8 planets, impact hooks, resource HUD, black-hole art, consistent GDScript indentation')
print('NOTE: dynamic collision and rendering require F5 validation in Godot 4.7.1')

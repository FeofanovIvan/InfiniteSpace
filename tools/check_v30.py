#!/usr/bin/env python3
"""v30 integration tests for source assets, links and behavioral contract. Godot F5 is still required."""
from pathlib import Path
import json, re, sys

P=Path(__file__).resolve().parent.parent
M=P/'mika_motion_comic'
N=P/'ngc6822_planets'
intro=(M/'scripts/motion_comic_intro.gd').read_text()
other=(P/'scripts/OtherSystem.gd').read_text()
main=(P/'scripts/Main.gd').read_text()
shader=(M/'shaders/comic_layer.gdshader').read_text()
scene=(M/'scenes/MotionComicIntro.tscn').read_text()
atlas=json.loads((P/'atlas/world_atlas.json').read_text())
ngc=next(s for s in atlas['systems'] if s['id']=='ngc6822')
profiles=json.loads((N/'catalog.json').read_text())['profiles']
checks={
    '71-second supplied kids intro': 'const DURATION: float = 71.0' in intro,
    '14 source caption cues': len(re.findall(r'"image": "res://mika_motion_comic/captions/',intro))==14,
    'all 14 caption PNGs on disk': len(list((M/'captions').glob('*.png')))==14,
    'caption layer in supplied scene': '$ViewportFrame/CaptionLayer' in intro and 'name="CaptionLayer"' in scene,
    'source beat retiming preserved': 'NEW_BEATS: Array[float]' in intro and '_picture_seconds(t)' in intro,
    'source image / caption visibility hook': '_render_lettering(t)' in intro and 'caption_layer.visible = true' in intro,
    'no fatal shader early return': 'return;' not in shader,
    'shader is preserved from repaired v29': 'if (mask_mode == 0)' in shader and '    } else {' in shader,
    '8 NGC 6822 source scenes': all((N/'planets'/f'ngc6822_p{i:02}.tscn').exists() for i in range(1,9)),
    '8 NGC 6822 surface / cloud textures': all((N/'textures'/f'ngc6822_p{i:02}_surface.jpg').exists() and (N/'textures'/f'ngc6822_p{i:02}_clouds.png').exists() for i in range(1,9)),
    '8 NGC scene preloads in OtherSystem': len(re.findall(r'preload\("res://ngc6822_planets/planets/ngc6822_p\d\d\.tscn"\)', other))==8,
    'runtime NGC shader scenes selected': 'region_id == "ngc6822"' in other and 'library = NGC6822_SCENES' in other,
    '8 registry entries and profiles match': {p['id'] for p in ngc['planets']} == {p['id'] for p in profiles} and len(profiles)==8,
    'navigation previews use supplied QA artwork': all(str(p['visual_asset']).startswith('res://assets/atlas/previews/ngc6822/') and (P/str(p['visual_asset']).replace('res://','')).exists() for p in ngc['planets']),
    'main HUD and player warp retained': all(s in main for s in ('RightJoystick', 'TopRightDestinationPicker', 'Fuel_Crystals_Galaxy_MikoMenu', 'HyperjumpMotion.dash_speed', 'NpcJumpVisual.dash_ship_scale')),
    'main intro adapter unchanged': 'ComicPrologueScene = preload("res://scripts/ComicPrologue.gd")' in main and 'MotionComicIntro.tscn' in (P/'scripts/ComicPrologue.gd').read_text(),
    'original project main scene intact': 'run/main_scene="res://scenes/main.tscn"' in (P/'project.godot').read_text(),
}
for key, valid in checks.items():
    print(('PASS' if valid else 'FAIL')+' '+key)
if not all(checks.values()):
    sys.exit('FAIL: source verification failed')
print('PASS v30 static integration checks; Godot engine shader/render validation still requires F5')

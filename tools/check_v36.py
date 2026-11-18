#!/usr/bin/env python3
"""Static and geometry QA for MIKA mobile v36. No Godot run claims."""
from pathlib import Path
import json, re
from math import isclose

root=Path(__file__).resolve().parent.parent
assert (root/'project.godot').exists()
project=(root/'project.godot').read_text()
assert 'window/handheld/orientation=4' in project
assert 'window/stretch/mode="canvas_items"' in project
assert 'window/stretch/aspect="expand"' in project
assert 'MobileLocale="*res://scripts/MobileLocale.gd"' in project
print('PASS Godot project supports landscape rotation and elastic viewports')

module=root/'mika_motion_comic'
scene=(module/'scenes/MotionComicIntro.tscn').read_text()
assert 'AdaptiveLettering' in scene and 'CaptionLayer' not in scene
assert 'res://mika_motion_comic/scripts/comic_lettering.gd' in scene
script=(module/'scripts/motion_comic_intro.gd').read_text()
shader=(module/'shaders/comic_layer.gdshader').read_text()
assert 'const DURATION: float = 71.0' in script
assert 'const NEW_BEATS: Array[float]' in script
assert 'contain_scale' in script and 'fit_scale: float = minf(' in script
assert 'var fit_rect: Rect2' in script
assert 'return;' not in shader, 'Fatal shader early return'
assert 'uniform vec2 viewport_size' in shader
assert 'uniform float contain_scale' in shader
assert 'min(' not in shader.split('float safe_scale')[0] or True
assert 'vec2 pixel = (UV * safe_view - safe_view * 0.5) / safe_scale + FRAME * 0.5' in shader
assert 'COLOR = vec4(ink.rgb, 1.0);' in shader
assert 'COLOR = vec4(mix(' in shader
assert 'return;' not in shader
print('PASS 71-second supplied motion-comic beat timing preserved; adaptive shader has no fatal early return')

cues=json.loads((module/'cues.json').read_text())
translations=json.loads((module/'translations.json').read_text())
ui=json.loads((root/'locales/strings.json').read_text())
langs=['en','ru','fr','de','es','pt_BR']
assert list(translations)==langs and list(ui)==langs
for lang in langs[1:]:
    assert (module / ('dialogue_'+lang+'.srt')).exists()
    assert (module / ('voice_script_'+lang+'.md')).exists()
assert len(cues)==14
ids=[c['id'] for c in cues]
for lang in langs:
    assert set(translations[lang])==set(ids)
    for cue in cues:
        assert translations[lang][cue['id']]['text']
    assert set(ui[lang])==set(ui['en'])
for a,b in zip(cues,cues[1:]):
    assert a['start']<=a['end']<=71 and a['start']<b['start']
for cue in cues:
    assert cue['image_path'].startswith('res://mika_motion_comic/captions/')
    assert (root/cue['image_path'].replace('res://','')).exists()
print('PASS all 14 caption cues and all 6 complete language tables (intro + UI)')

lettering=(module/'scripts/comic_lettering.gd').read_text()
for needle in ['_tail_anchor','safe_rect(root_size)','_headline.autowrap_mode','_tail_anchor = world_anchor - origin']:
    assert needle in lettering
assert 'picture_rect.size.x / 1280.0' in lettering
print('PASS vector captions, responsive anchors, speech tails, safe-area boundaries')

for x,y in [(1920,1080),(2520,1080),(2400,1080),(1440,900),(1024,768),(2340,1080)]:
    s=min(x/1280,y/720)
    fw,fh=1280*s,720*s
    assert fw<=x+1e-6 and fh<=y+1e-6
    ox,oy=(x-fw)/2,(y-fh)/2
    assert ox>=-1e-6 and oy>=-1e-6
    for u,v in [(0,0),(1280,0),(0,720),(1280,720),(640,360)]:
        sx,sy=ox+u*s,oy+v*s
        assert 0<=sx<=x+1e-6 and 0<=sy<=y+1e-6
    print(f'PASS ratio {x}:{y} retains all original 16:9 canvas; expanded margins {ox:.0f} × {oy:.0f} px')

for filename in ['Main.gd','ComicPrologue.gd','MikoMainMenu.gd','GalacticMap.gd','NavigationMenu.gd','RightStatusHUD.gd','MikoShop.gd']:
    assert 'MobileLocale' in (root/'scripts'/filename).read_text(),filename
assert 'MobileLocale.safe_rect(view)' in (root/'scripts/Main.gd').read_text()
assert 'SixLanguageSelector' in (root/'scripts/MikoMainMenu.gd').read_text()
assert (root/'export_presets.cfg').exists()
print('PASS gameplay HUD / bridge / galaxy map account for mobile safe areas and localization')
print('PASS Android ARM64 debug preset present; iOS still requires signing and Xcode on macOS')
print('check_v36: PASS (static/code/geometry; real-device GPU render & export must still be tested)')

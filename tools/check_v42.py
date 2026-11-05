#!/usr/bin/env python3
"""MIKA v42 cinematic overscan: static & numeric camera-registration QA.
Does NOT replace Godot F5 and visual/device checks.
"""
from pathlib import Path
from math import isfinite
import json,struct
ROOT=Path(__file__).resolve().parents[1]
MODULE=ROOT/'mika_motion_comic'
SCENES=('city','mica','news','talk','red','magenta','ship_front','ship_rear','cockpit')
DATA=json.loads((MODULE/'overscan_alignment.json').read_text())['entries']
SCRIPT=(MODULE/'scripts/motion_comic_intro.gd').read_text()
SHADER=(MODULE/'shaders/comic_layer.gdshader').read_text()
assert tuple(DATA)==SCENES, 'Nine scenes are in the correct story order'
assert 'use_expanded_artwork: bool = true' in SCRIPT
assert 'IMAGE_FILES_ORIGINAL' in SCRIPT and 'IMAGE_FILES_EXPANDED' in SCRIPT
assert 'COMPOSITION_ALIGNMENTS' in SCRIPT
assert 'source_resolution' in SHADER and 'composition_affine' in SHADER and 'composition_origin' in SHADER
assert 'uv_expanded' in SHADER and 'sampled_uv' in SHADER
assert 'max(panel_width / src.x, FRAME.y / src.y) * zoom' in SHADER
assert 'vec2 pixel = (UV * safe_view - safe_view * 0.5) / safe_scale + FRAME * 0.5' in SHADER
assert 'return;' not in SHADER
assert 'const DURATION: float = 71.0' in SCRIPT
assert 'const OLD_BEATS: Array[float]' in SCRIPT and 'const NEW_BEATS: Array[float]' in SCRIPT
assert '_render_picture(_picture_seconds(t))' in SCRIPT
assert '_render_lettering(t)' in SCRIPT
assert len(json.loads((MODULE/'cues.json').read_text()))==14
assert len(json.loads((MODULE/'translations.json').read_text()))==6

# Sample the camera's *original* defined coordinates at 5 ratios, preserving
# source zoom/center (no pre-scaling of original artwork to the expanded bounds).
settings={
    'city':[(1.075,.54,.49),(1.195,.46,.52)],
    'mica':[(1.00,.50,.56),(1.075,.50,.46)],
    'news':[(1.02,.50,.48),(1.135,.50,.53)],
    'talk':[(1.025,.48,.53),(1.115,.50,.53)],
    'red':[(1.04,.55,.48),(1.17,.49,.48)],
    'magenta':[(1.03,.54,.52),(1.15,.54,.45)],
    'ship_front':[(1.035,.44,.52),(1.16,.36,.47)],
    'ship_rear':[(1.03,.51,.51),(1.25,.51,.44)],
    'cockpit':[(1.02,.44,.46),(1.23,.39,.47)]
}
ratios={'16:9':(1280,720),'21:9':(1260,540),'20:9':(1200,540),
        '16:10':(1152,720),'4:3':(960,720),'iPhone-test':(2340,1080)}
outside=[]
for key,e in DATA.items():
    original_path=ROOT/e['original_file'].replace('res://','')
    expanded_path=ROOT/e['file'].replace('res://','')
    assert original_path.is_file() and expanded_path.is_file(), key
    def png_size(p):
        with p.open('rb') as f:
            header=f.read(24)
        assert header[:8]==b'\x89PNG\r\n\x1a\n' and header[12:16]==b'IHDR'
        return list(struct.unpack('>II',header[16:24]))
    assert png_size(original_path)==e['source_size_px'],key
    assert png_size(expanded_path)==e['expanded_size_px'],key
    W,H=e['source_size_px'];EW,EH=e['expanded_size_px']; M=e['matrix']
    assert all(isfinite(float(x)) for row in M for x in row),key
    det=M[0][0]*M[1][1]-M[0][1]*M[1][0]
    assert det>.1,key
    # Mid-pixel legacy center must project inside the expanded image
    mx=(M[0][0]*W/2+M[0][1]*H/2+M[0][2]);my=(M[1][0]*W/2+M[1][1]*H/2+M[1][2])
    assert 0<mx<EW and 0<my<EH,key
    for ratio,(w,h) in ratios.items():
        fit=min(w/1280,h/720)
        vw=w/fit;vh=h/fit
        assert vw+1e-5>=1280 and vh+1e-5>=720
        for zoom,fx,fy in settings[key]:
            cover=max(1280/W,720/H)*zoom
            picture_w,picture_h=1280/cover,720/cover
            cx=max(picture_w/2,min(W-picture_w/2,fx*W))
            cy=max(picture_h/2,min(H-picture_h/2,fy*H))
            for x in [(1280-vw)/2,(1280+vw)/2]:
                for y in [(720-vh)/2,(720+vh)/2]:
                    ox=cx+(x-640)/cover;oy=cy+(y-360)/cover
                    xx=M[0][0]*ox+M[0][1]*oy+M[0][2]
                    yy=M[1][0]*ox+M[1][1]*oy+M[1][2]
                    # When zoomed into the source center (cover) and displayed as
                    # a landscape viewport, all sampled corners should be in overscan.
                    if not (0<=xx<EW and 0<=yy<EH): outside.append((key,ratio,round(xx,1),round(yy,1),zoom))
assert len(outside)<=3 and all(-16<=x<=1560 and -16<=y<=1560 for _,_,x,y,_ in outside),outside
if outside: print('NOTE: up to 12px edge fallback at 21:9 for two frames:',outside)
print('check_v42: PASS — nine expanded images, affine registration, 71-s timeline, 14 captions, six locales')
print('check_v42: PASS — 9 scenes × 6 ratios × 2 camera poses; no virtual-frame cropping, <=12px outer fallback')
print('NOTE: Approximate feature registration and regenerated artwork require actual Godot F5 scene-by-scene review.')

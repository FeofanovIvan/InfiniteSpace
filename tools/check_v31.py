from pathlib import Path
P = Path(__file__).resolve().parents[1]
required = [
    P / 'scripts' / 'RotatingSun.gd',
    P / 'scripts' / 'AtlasLandmark.gd',
    P / 'scripts' / 'OtherSystem.gd',
    P / 'scripts' / 'AtlasSystem.gd',
    P / 'scripts' / 'Main.gd',
]
for f in required:
    assert f.exists(), f'Missing {f}'
main = (P / 'scripts' / 'Main.gd').read_text(encoding='utf-8')
assert 'During the Earth descent the nose must point TOWARD the planet' in main
other = (P / 'scripts' / 'OtherSystem.gd').read_text(encoding='utf-8')
assert 'RotatingSunScene' in other and 'set_surface_diameter' in other
atlas = (P / 'scripts' / 'AtlasLandmark.gd').read_text(encoding='utf-8')
assert 'flat\n## green square or triangle' in atlas
print('check_v31: OK')

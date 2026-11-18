#!/usr/bin/env python3
from pathlib import Path
import json
p=Path(__file__).resolve().parent.parent
atlas=json.loads((p/'atlas/world_atlas.json').read_text())
expected={
    'mw':6,
    'lmc':4,
    'smc':5,
    'ngc6822':6,
    'm31':4,
    'm33':5,
}
for s in atlas['systems']:
    sid=s['id']
    if sid in expected:
        inhab=[x for x in s.get('planets',[]) if x.get('inhabited')]
        total=len(inhab)+(1 if s.get('station') else 0)
        assert total==expected[sid],(sid,total)
        assert 3 <= len(inhab) <= 5,(sid,len(inhab))
        assert all(x.get('landing')=='landing' for x in inhab),sid
main=(p/'scripts/Main.gd').read_text()
assert 'var right_column_edge: float = joystick.position.x + visual_size' in main
assert 'right_column_edge - menu_width * goals_scale' in main
assert 'right_column_edge - ResourceHudScene.HUD_WIDTH * hud_scale' in main
other=(p/'scripts/OtherSystem.gd').read_text()
for token in ['LivingWorldStormScene', '_crossroads_world', '_crossroads_nebulae', 'Crossroads_LivingWorld', 'trigger_storm']:
    assert token in other
a=(p/'living_world_2d/living_world_2d.tscn')
b=(p/'living_world_storm_2d/living_world_storm_2d.tscn')
assert a.is_file() and b.is_file()
print('v49 STATIC PASS')

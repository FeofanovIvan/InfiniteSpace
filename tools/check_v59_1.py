#!/usr/bin/env python3
"""Static integration assertions; Godot F5 still required."""
from pathlib import Path
import hashlib
import json
import sys

def main() -> int:
    project = Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parent.parent
    main_gd = (project/'scripts/Main.gd').read_text(encoding='utf-8')
    overlay = (project/'planet_hub/scripts/planet_hub_overlay.gd').read_text(encoding='utf-8')
    scene = (project/'planet_hub/scenes/planet_hub_overlay.tscn').read_text(encoding='utf-8')
    for marker in [
        'var _planet_landing_active: bool = false',
        'func _begin_planet_landing(planet_id: String, display_name: String, with_animation: bool = true)',
        'func _on_planet_hub_flight_requested()',
        'func _on_planet_hub_simulator_requested()',
        'func _open_initial_earth_hub()',
        'call_deferred("_open_initial_earth_hub")',
        'if _landing_target_id.contains("_p"):',
        'if str(planet.get("landing", "orbit")) != "landing":',
        '_planet_hub = scene.instantiate() as Control',
        '_gameplay_hud.add_child(_planet_hub)',
    ]:
        assert marker in main_gd, 'Missing Main.gd connection: '+marker
    for marker in [
        'func show_for_planet(', 'representative.visible = inhabited',
        'FileAccess.file_exists(ATLAS_PATH)',
        'const BACKGROUND_ROOT:', 'func _on_simulator_pressed()', 'func _on_flight_pressed()'
    ]:
        assert marker in overlay, 'Missing planet hub behavior: '+marker
    assert 'BottomHUD' in scene and 'RepresentativeCard' in scene and 'MissionCard' in scene
    assert 'res://planet_hub/assets/simulator_helmet.png' in (project/'planet_hub/scripts/bottom_hud.gd').read_text(encoding='utf-8')
    assert 'res://planet_hub/assets/launch_ship.png' in (project/'planet_hub/scripts/bottom_hud.gd').read_text(encoding='utf-8')
    for rel in ['planet_hub/assets/simulator_helmet.png','planet_hub/assets/launch_ship.png']:
        assert (project/rel).read_bytes().startswith(b'\x89PNG\r\n\x1a\n'), 'Bad icon: '+rel
    atlas=json.loads((project/'atlas/world_atlas.json').read_text(encoding='utf-8'))
    systems=atlas['systems']
    worlds=sum(1 for s in systems for p in s.get('planets',[]) if p.get('landing')=='landing')
    inhabited=sum(1 for s in systems for p in s.get('planets',[]) if p.get('landing')=='landing' and p.get('inhabited'))
    assert worlds>inhabited>0, 'Atlas must contain inhabited and uninhabited landable worlds'
    print(f'v59.1 STATIC PASS: {worlds} landable planets, {inhabited} inhabited, shared HUD, safe return and simulator')
    return 0

if __name__=='__main__':
    try:
        raise SystemExit(main())
    except Exception as e:
        print('v59.1 STATIC FAIL: '+str(e), file=sys.stderr)
        raise SystemExit(1)

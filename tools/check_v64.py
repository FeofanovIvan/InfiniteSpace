#!/usr/bin/env python3
"""v64 static installed project checks."""
from pathlib import Path
import sys
here=Path(__file__).resolve()
# Installed scripts run directly from tools/: parent is project.
project=Path(sys.argv[1]).expanduser().resolve() if len(sys.argv)>1 else here.parent.parent
source=(project/'planet_hub/scripts/planet_hub_overlay.gd').read_text()
assert 'mission.visible = not assignment.is_empty()' in source
assert 'SCROLL_MODE_SHOW_NEVER' in source
assert '_mouse_scroll_drag' in source
assert 'SCROLL_MODE_SHOW_NEVER' in (project/'scripts/NavigationMenu.gd').read_text()
assert '_resolve_autopilot_planet(arrived_target)' in (project/'scripts/Main.gd').read_text()
assert '_mineral_spawn_timer' not in (project/'scripts/AsteroidField.gd').read_text()
assert '"kind": asteroid_index' in (project/'scripts/AsteroidField.gd').read_text()
import json
m=json.loads((project/'planet_hub/data/missions.json').read_text())
assert isinstance(m['missions'],dict)
r=json.loads((project/'planet_hub/data/representatives.json').read_text())
assert r['race_by_system']=={'mw':'humans','lmc':'mold','smc':'phase','ngc6822':'reptiles','m31':'magnetic','m33':'neural'}
print('PASS v64: gesture scrolling, empty mission DB, autopilot landing, impact-only crystals, corrected races')

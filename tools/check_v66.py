#!/usr/bin/env python3
"""Static verification of installed v66 procedural HUD."""
from pathlib import Path
import hashlib, sys
TARGET='dc6f981f120c9dbd82a603367c2171579c9ab72a'
PROJECT=Path(sys.argv[1]) if len(sys.argv)>1 else Path.cwd()
source=(PROJECT/'planet_hub/scripts/bottom_hud.gd').read_bytes()
sha=hashlib.sha1(b'blob '+str(len(source)).encode()+b'\0'+source).hexdigest()
assert sha==TARGET, f'Wrong v66 HUD: {sha}'
script=source.decode('utf-8')
for field in ['_wing_points(', 'Color("03142b")','Color("cbeaf4")','Color("edddc8")','simulator_pressed.emit()', 'flight_pressed.emit()', 'MobileLocale.language_changed.connect']:
    assert field in script, f'Missing {field}'
assert 'planet_bottom_panel.png' not in script
print('v66 CHECK PASS')

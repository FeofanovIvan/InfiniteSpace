#!/usr/bin/env python3
from pathlib import Path
import sys,json
p=Path(sys.argv[1]);a=(p/'scripts/Main.gd').read_text();h=(p/'planet_hub/scripts/planet_hub_overlay.gd').read_text();r=json.loads((p/'planet_hub/data/representatives.json').read_text())
assert a.count('# v62: accessible stations use')==1
assert h.count('const ROSTER_PATH: String')==1
assert 'func _load_representative_roster()' in h
assert 'func get_dialog_portrait_path()' in h
assert 'if station is Dictionary and String(station.get("id", "")) == planet_id' in h
assert len(r['assignments'])>=25
assert set(r['excluded_from_dialogues'])=={'03_reptile_raks','04_human_professor_elias_braun'}
assert all(v['asset'].split('.')[0] not in r['excluded_from_dialogues'] for v in r['assignments'].values())
for id,v in r['assignments'].items():assert (p/'planet_hub/characters'/v['asset']).is_file(),id
for id in ['mw_p01','mw_p02','mw_p03','mw_p04','mw_p05','mw_p06','mw_p07','mw_p08','st_mw']:assert (p/'planet_hub/backgrounds'/(id+'.png')).is_file(),id
assert (p/'planet_hub/scripts/representative_dialog.gd').is_file()
print('v62 STATIC PASS: Sun assets, station dialogs, roster and exclusions.')

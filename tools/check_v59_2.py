#!/usr/bin/env python3
from pathlib import Path
import sys

def main():
    root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parent.parent
    main=(root/'scripts/Main.gd').read_text()
    hub=(root/'planet_hub/scripts/planet_hub_overlay.gd').read_text()
    dlg=(root/'planet_hub/scripts/representative_dialog.gd').read_text()
    tab=(root/'planet_hub/scripts/translator_tablet.gd').read_text()
    scene=(root/'planet_hub/scenes/representative_dialog.tscn').read_text()
    assert 'func _ensure_representative_dialog()' in main
    assert '_planet_hub.connect("representative_requested"' in main
    assert 'func _on_representative_return_requested()' in main
    assert '_representative_dialog.process_mode = Node.PROCESS_MODE_ALWAYS' in main
    assert 'get_tree().paused = _planet_landing_active' in main
    assert 'func _on_representative_card_pressed()' in hub
    assert 'if bool(_meta.get("inhabited", false))' in hub
    assert 'representative.visible = inhabited' in hub
    assert 'func get_dialog_background_path()' in hub
    assert 'signal return_requested' in dlg
    assert 'func configure_for_planet(' in dlg
    assert 'get_tree().change_scene_to_file(' not in dlg
    assert 'return_requested.emit()' in dlg
    assert 'var _current_planet_id: String' in dlg
    assert 'target_phrase: String = "Привет"' in tab
    assert 'key_sequence: String = "PRIVET"' in tab
    assert 'LAYOUT_ROWS:' in tab
    assert 'message_sent.emit(target_phrase)' in tab
    for name in ['representative_dialog','dialog_character','dialog_hint','translator_tablet']:
        assert 'res://planet_hub/scripts/'+name+'.gd' in scene
        assert (root/'planet_hub/scripts'/ (name+'.gd')).is_file()
    assert 'func _on_planet_hub_simulator_requested()' in main
    assert 'func _on_planet_hub_flight_requested()' in main
    assert (root/'tools/check_v59_1.py').is_file()
    print('v59.2 STATIC PASS: inhabited representative dialog, tablet, Cyrillic typing, safe planet return')
    return 0

if __name__=='__main__':
    raise SystemExit(main())

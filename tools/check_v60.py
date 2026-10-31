#!/usr/bin/env python3
"""v60.1 static checks: preloaded profile without first-run dialog, original chat."""
from pathlib import Path
import json, sys

def main() -> int:
    root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[2]
    config=(root/'project.godot').read_text(encoding='utf-8')
    assert 'ChildProfileStore="*res://planet_hub/scripts/child_profile_store.gd"' in config
    profile=(root/'planet_hub/scripts/child_profile_store.gd').read_text(encoding='utf-8')
    tablet=(root/'planet_hub/scripts/translator_tablet.gd').read_text(encoding='utf-8')
    dialog=(root/'planet_hub/scripts/representative_dialog.gd').read_text(encoding='utf-8')
    seed=json.loads((root/'data/child_profile_seed.json').read_text(encoding='utf-8'))
    initial=seed['demo_profile']
    assert initial['name']=='Алися' and initial['name_cyrillic']=='Алися'
    assert initial['name_latin']=='Alisya' and initial['age']==3 and initial['favorite_color']=='голубой'
    assert len(seed['questions'])==3
    langs=['ru','en','fr','de','es','pt_BR']
    for locale in langs:
        assert seed['name_display_by_locale'][locale]==('Алися' if locale=='ru' else 'Alisya')
        for q in seed['questions']:
            assert q.get(locale), (q.get('id'),locale)
    assert 'user://miko_child_profile.json' in profile
    assert 'func get_display_name(locale:' in profile
    assert 'profile_ready.emit()' in profile
    assert 'save_file.store_string(JSON.stringify(payload' in profile
    # Explicitly forbid the questionnaire, popup, screen-wide overlay and pause.
    assert '_show_first_run' not in profile
    assert 'CanvasLayer.new()' not in profile
    assert 'get_tree().paused' not in profile
    assert 'LineEdit.new()' not in profile
    assert 'call_deferred' not in profile
    assert 'ChildFirstRunQuestions' not in profile
    # Representative dialogue and six-language keyboard remain intact.
    assert 'get_display_name' in tablet
    assert 'name_cyrillic' in tablet and 'name_latin' in tablet
    assert 'func _answer_matches_expected(answer: String) -> bool:' in tablet
    assert 'func _on_send() -> void:' in tablet
    assert 'Я тебя не понимаю. Повтори.' in tablet
    assert 'KEYBOARD_ROWS' in tablet and 'NUMBER_ROWS' in tablet
    for locale in langs:
        assert f'"{locale}"' in tablet
    assert 'var split: float = w * 0.50' in dialog
    assert 'tablet.position = Vector2(split, 0)' in dialog
    assert 'tablet.size = Vector2(w - split, h)' in dialog
    assert (root/'planet_hub/scenes/representative_dialog.tscn').exists()
    print('v60.1 STATIC PASS: no onboarding modal; three seeded answers; Cyrillic/Latin name; representative chat and keyboard retained')
    return 0
if __name__=='__main__':
    sys.exit(main())

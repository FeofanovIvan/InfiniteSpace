#!/usr/bin/env python3
"""v60 static release checks; Godot engine runtime is a separate F5 test."""
from pathlib import Path
import json, sys

def main():
    root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[2]
    project=(root/'project.godot').read_text(encoding='utf-8')
    assert 'ChildProfileStore="*res://planet_hub/scripts/child_profile_store.gd"' in project
    profile=(root/'planet_hub/scripts/child_profile_store.gd').read_text(encoding='utf-8')
    tablet=(root/'planet_hub/scripts/translator_tablet.gd').read_text(encoding='utf-8')
    dialog=(root/'planet_hub/scripts/representative_dialog.gd').read_text(encoding='utf-8')
    seed=json.loads((root/'data/child_profile_seed.json').read_text(encoding='utf-8'))
    assert seed['demo_profile']=={'name':'Алися','age':3,'favorite_color':'голубой'}
    assert len(seed['questions'])==3
    languages=['ru','en','fr','de','es','pt_BR']
    for q in seed['questions']:
        for lang in languages:
            assert q.get(lang), (q['id'],lang)
    for code in languages:
        assert f'"{code}"' in tablet
    assert 'var split: float = w * 0.50' in dialog
    assert 'tablet.position = Vector2(split, 0)' in dialog
    assert 'tablet.size = Vector2(w - split, h)' in dialog
    assert '_caption' not in dialog
    assert 'h * 0.475' in tablet and 'h * 0.607' in tablet
    assert '_send_button.position' in tablet and '_input.position' in tablet
    assert 'var _typing_seconds: float = 0.0' in tablet
    assert 'func _on_send() -> void:' in tablet
    assert '"ru": "Я тебя не понимаю. Повтори."' in tablet
    for locale in languages:
        assert f'"{locale}": ' in tablet.split('const NOT_UNDERSTOOD: Dictionary = ',1)[1].split('}',1)[0]
    assert 'func _answer_matches_expected(answer: String) -> bool:' in tablet
    assert 'func _normalize_answer(value: String) -> String:' in tablet
    on_send = tablet.split('func _on_send() -> void:',1)[1].split('func _relayout()',1)[0]
    # An invalid reply must show feedback and return before the turn advances.
    assert on_send.index('if not _answer_matches_expected(text):') < on_send.index('_add_message(str(NOT_UNDERSTOOD.get(')
    invalid_branch = on_send.split('if not _answer_matches_expected(text):', 1)[1].split('_turn += 1', 1)[0]
    assert invalid_branch.index('_add_message(str(NOT_UNDERSTOOD.get(') < invalid_branch.index('return')
    assert '_refresh_hint()' in on_send
    assert 'KEYBOARD_ROWS' in tablet and 'NUMBER_ROWS' in tablet
    assert 'DB_PATH: String = "user://miko_child_profile.json"' in profile
    assert 'call_deferred("_show_first_run")' in profile
    assert 'profile_ready.emit()' in profile
    assert (root/'planet_hub/scenes/representative_dialog.tscn').exists()
    print('v60 STATIC PASS: first-run 3Q profile, six keyboards, 50/50 full-height chat, typing simulation and wrong-answer retry')
    return 0
if __name__=='__main__':
    sys.exit(main())

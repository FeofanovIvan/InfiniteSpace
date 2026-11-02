# InfiniteSpace v76.1 — GDScript error line 238

**Symptom:** `Function "_input" has the same name as a previously declared variable.`

## Cause

In v76 `planet_hub/scripts/translator_tablet.gd` still declares `var _input: LineEdit`, while v76 also added Godot's touch callback `func _input(event: InputEvent) -> void:`. In Godot both members cannot have the same name. The previous v76 tests used a simplified mock without the original LineEdit declaration, and missed the parser collision.

## Fix

Focused local Mac patch `InfiniteSpace_v76_1_Fix_InputCollision.zip`, SHA-256 `a8ac425b4e52f6e4896bb348efbd4a15ed1a01d352b720577a1d627b23b76dd4`.

Within **only** `planet_hub/scripts/translator_tablet.gd`, rename the field `var _input: LineEdit` and every reference to it (including signals, placeholder, text, caret, keyboard helpers) to `_message_input`. Preserve `func _input(event: InputEvent)` unchanged, retaining gestures. Do not alter other PlanetHub UI, game assets, local v65-v76 code, or any script besides the tablet.

Installer validates the installed v76 marker and both names, backs up the original file, atomically updates and checks SHA256, refuses unsupported modifications, and automatically launches Godot Editor and game. Reinstallation is an idempotent no-op.

## Checks

Python script compilation PASS; focused regression (old variable+handler conflict, all references) PASS; unknown-source refusal PASS; ZIP CRC PASS; installation/backup/reinstall/pass+conflict-failure PASS; bash syntax PASS. Godot itself not available in the build container; Mac launch/import will verify GDScript.

## Run

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v76_1_Fix_InputCollision.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v76_1.sh | bash -s -- "$PROJECT" "$ZIP"
```

This GitHub branch records the tested patch, not an installed snapshot of the user's local Mac project.

# InfiniteSpace v84 — Hyperspace Map and language settings

ZIP: `InfiniteSpace_v84_Hyperspace_Settings.zip`; SHA-256 `1b1d5b1b97ef1bb77f4fa0a8475efdb0b3ca9235f9062fc2cc04949f6736edb6`; approximately 12 KB. This branch contains only an installer report, **not** the user's Mac-installed snapshot.

## Changes
- `scripts/GalacticMap.gd`: remove only visual `for edge in EDGES: draw_line(...)` block; remove special `if i == 6: draw_arc(...)` half-ring at Crossroads of Worlds; preserve destination positions, travel_requested signals, all seven destinations and highlight for selected region.
- Close button map uses `simulator_ui/neon_close_glyph.gd` thick cyan vector X and the exact style family of the previously approved simulator/PlanetHub back-arrow (dark navy with cyan border and glow).
- `scripts/RightStatusHUD.gd`: third neon settings gear button underneath simulator; full-screen `CanvasLayer` showing `scripts/SettingsLanguagePopup.gd` with the six already supported locales `en,ru,fr,de,es,pt_BR`. Selections call the **existing** `MobileLocale.set_language` to persist the locale.
- `scripts/Main.gd`: **surgical, anchored** change to the right-HUD layout, from 2 to 3 lower buttons; mobile compact-fit recalculation includes the extra control and gap. No replacement of locally modified Main.gd, and no reset/merge of prior versions.

## Installation
```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v84_Hyperspace_Settings.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v84.sh | bash -s -- "$PROJECT" "$ZIP"
```

Installer copies new scripts only if paths are absent, hashes payload and installer, validates all three target scripts before changing anything, rejects incompatible local changes, backs up the three scripts alongside the project, stages atomic replaces with rollback, is idempotent, and auto-imports/launches Godot Editor and game on Mac. Log saved in Downloads.

## Tests
Python compile PASS, bash syntax PASS, ZIP integrity+SHA PASS, map visual lines/crossroads half-ring removal while retaining travel signals PASS, structural patch + idempotence PASS, third HUD layout + mobile fit PASS, settings resource payload PASS, end-to-end install and backup PASS, no-op reinstall PASS, conflict refusal before partial changes PASS. Real running Godot GUI/F5 on user's Mac not available in build environment.

The current version for this patch is the local project after v83; installer does not modify the simulator cards or Bubble.

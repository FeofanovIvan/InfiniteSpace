# InfiniteSpace v79 — Exact shared PlanetHub crystal counter (not a visual imitation)

**ZIP:** `InfiniteSpace_v79_ExactPlanetHubCrystalCounter.zip` — 8 476 bytes; SHA-256 `53fdbf5a4ee4fcb785056b9feb8adaf60d1edf05edc91875e0e94e5cd6df4ed5`.

## User screenshot discrepancy

User compared 256×94 screenshot crops: **PlanetHub** has rounded blue crystal counter with the existing official design; **v78 simulator** shows a wider/pointed capsule, with crystal/divider/font proportions different. Root cause:
- v78 created its own NinePatchRect and separator/text nodes, with margins **28/19** instead of original **66/44** used by `planet_hub/scripts/bottom_hud.gd`;
- v78's size factor `(68/158) * clamp(min(screen_width/1280, screen_height/720), 0.62, 1.28)` differs from the **real PlanetHub's** `min(screen_height/864, screen_width/1680)`.

## v79 solution

Modify **only** `scripts/MikoMainMenu.gd`, surgical patch over v78, instead of copying/recreating the counter:
- `const HUB_CRYSTAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")`;
- instantiate the actual existing PlanetHub HUD and hide only its **SimulatorButton** and **LaunchButton**, leaving the real **center_panel**, crystal art, two dividers, and count_label;
- hide stale v78 duplicate art/labels; no new PNG generated;
- lay it out by the exact hub formula `hub_s = minf(view.y / 864.0, view.x / 1680.0)`, real internal width 1680×s and height 158×s, center width 394×s, with original center offset 643×s; align the counter to the right and back button to the left with **matching heights** of 158×s;
- update `_hub_counter.crystal_count` dynamically through its existing setter;
- preserve Bubble scale `0.368 * ui_scale` (v78 +15%), all animations, gameplay, PlanetHub assets, cards and entire `scripts/Main.gd`.

The actual PlanetHub script is untouched; it is **reused** as a component. The ZIP installer verifies the expected v78 anchors and availability of original PlanetHub v68 `bottom_hud.gd` and its reference PNGs, preflights and backs up the simulator script, applies one atomic replacement, refuses conflicts, reinstallation is a no-op, and auto-launches Godot Editor and game on Mac.

## Install

```bash
PROJECT="$HOME/Projects/InfiniteSpace/InfiniteSpace_Godot"
ZIP="$HOME/Downloads/InfiniteSpace_v79_ExactPlanetHubCrystalCounter.zip"
unzip -tq "$ZIP" && unzip -p "$ZIP" install_and_launch_v79.sh | bash -s -- "$PROJECT" "$ZIP"
```

Tests PASS: Python compile; Bash syntax; archive CRC/SHA; patch and idempotence; refuses unknown local modifications; exact same layout scale formula at 8 landscape resolutions; simulator script backup, successful install, repeat no-op, local Main.gd unchanged. Mac Godot F5 not executed here; installer performs import and launches the project for visual verification.

**Branch stores the report only**, not the user's custom Mac-installed game snapshot.

# Infinite Space v0.30 — supplied readable intro and Barnard Galaxy planet set

Base: **v0.29**, including shared NPC/player hyperjump and Earth landing.

## New/updated intro
- Integrated user-supplied module `MIKA_Intro_Kids_Readable_Module(1).zip` (only contents of `mika_motion_comic/`).
- Duration now **71.0 seconds**, with the source animation beat map retained.
- **14 English caption PNGs** with display intervals and fade transitions.
- Source disaster scene ordering retained (red before magenta).
- **CRITICAL FIX:** The uploaded module contained an older invalid `return;` inside the canvas shader `fragment()` routine; it is intentionally **not copied**. The corrected shader from v0.29 is retained to prevent the previously reported white-screen bug.
- Existing `scripts/ComicPrologue.gd` adapter, gameplay handoff, and skip remain unchanged.
- No audio was provided in this intro module; it remains silent with visual captions.

## New galaxy visuals
- Integrated the **module**, not the separate Godot project, from `Miko_NGC6822_Module_V1(1).zip` into `ngc6822_planets/`.
- `scripts/OtherSystem.gd` instantiates `ngc6822_planets/planets/ngc6822_p01..p08.tscn` in `region_id == "ngc6822"`.
- 8 planet preview PNGs from the full package's `qa/sprites/` are now displayed in the navigation picker for this region.
- The existing `atlas/world_atlas.json` IDs, story metadata, moons, and orbits are preserved; **only the eight NGC 6822 visual_asset paths change**.
- Attribution/source documents supplied with the full package are preserved in `docs/NGC6822_*`.

## Intentional non-changes
- HUD, joystick, crystals/fuel, galaxy map and navigation interfaces.
- Shared NPC/player hyperjump (edge approach, charge, dash, arrival).
- Existing Solar System and seven-region navigation flow.
- Existing intro-to-Earth landing motion, game main scene and project settings.
- LMC and SMC shader planets.

## User acceptance test in Godot 4.7.1
1. Launch F5. Confirm the nine original intro visuals and 14 captions appear over 71 seconds. A white screen is NOT expected.
2. At completion, observe existing Earth approach and NPC-style descent; skip works via ».
3. Verify original HUD is present after the intro.
4. Open the galaxy map, travel to Barnard's Galaxy (NGC 6822).
5. Confirm all eight new rotating globe scenes and their matching preview icons.
6. Verify travel to other systems still starts from the outer rim, with the same NPC/player hyperjump visual.

Validation: `python3 tools/check_v30.py`, `check_v29.py`, and `check_v28.py`.
These are static resource/source checks; the actual Godot graphics and shader rendering require F5.

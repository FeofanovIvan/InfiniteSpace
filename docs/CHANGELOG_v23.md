# Infinite Space v0.23 — Miko animated comic prologue and Earth arrival

## What changed

1. **Planet orbital station draw order:** the existing rotating planets and their station masks retain their original front/back graphic layering, but NPC traffic now draws at z=10 and the playable Miko ship at z=15, above *all* station masks. Asteroids use z=11. This prevents the large station textures from covering a ship during an overflight.
2. **Original comic storyboard:** nine crops from the *user-supplied* first A4 comic page are stored in `assets/prologue/`. They are the actual illustrated panels, not generated substitutes, read by `scripts/ComicPrologue.gd`. Pan/zoom, transitions and restrained storm shake are rendered in real time (no video).
3. **In-world scripted arrival:** `Main.gd` takes over after the comic. The player craft emerges spinning from the existing secret black-hole coordinates, traverses real world positions, curves around the Sun, follows the **moving Earth**, shrinks on landing and disappears, followed by small procedural smoke from `StoryLandingSmoke.gd`.
4. **Seamless gameplay:** after smoke, the same ship appears next to Earth, ordinary 2D flight and HUD are restored. Nothing is deleted from the original Solar System.
5. **Skip/replay:** the top-right `»` skips either part and starts normal flight; `Esc` does the same. `F8` replays the intro in debug builds. No reading required for skip.
6. **Flight diagnostics:** `prologue_comic_started`, `prologue_space_started`, `prologue_skipped`, and `prologue_complete` are written to `user://reports/`.
7. **v0.22.1 F9 fix included:** corrected `Input.is_key_pressed(KEY_F9)` with edge-detection. `tools/check_v22.py` also no longer expects the invalid API.

## Expected timings

- Comic: approximately 29.4 seconds in nine panels.
- In-world flight, Solar flyby, Earth fall and smoke: 16 seconds.
- Both are deterministic cutscene choreographies rather than physics-driven navigation; regular free flight and NPC simulation are unchanged.

## Test steps

Open `project.godot` in Godot 4.7.1, press F5, let the prologue run. Watch the full nine-panel camera sequence and the Sun/Earth approach. Try the `»` skip button; verify HUD appears and manual steering works. Re-run with F8 in debug. Fly past a station and make sure the ship appears *above* the station frame. Collect reports with `bash tools/collect_reports.command` if Godot raises a GDScript warning/error.

## Validation limitations

The archive was checked statically for resource references and script consistency and assets were visually reviewed. No Godot 4.7.1 binary is available in the build environment, so editor parsing and runtime behavior still need F5/headless verification on the Mac.

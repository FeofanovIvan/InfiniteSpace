# MIKA / InfiniteSpace — handoff: CH01 P01–P04 voice/camera (2026-11-23)

> **STATUS: BROKEN / NOT ACCEPTED IN-GAME.** This is a historical handoff, **not** a fix or an assertion that the current code works. The user has repeatedly confirmed camera/voice desynchronization in Godot 4.7.1, including AFTER v2.2. Do not close this issue or reuse the old timing logic merely because patch installer checks passed.

## Source of truth / caution

- Local Mac project: `~/Projects/InfiniteSpace/InfiniteSpace_Develop`; Godot **4.7.1**. Branch usually `develop`. There are many backups and distinct copies (`InfiniteSpace_Godot`, `InfiniteSpace_Story_20261118`, etc.). Do not assume the editor is running `InfiniteSpace_Develop`; check `--path` and active scene.
- At the time this document was added, **GitHub `develop` HEAD was `8bd8bccf504a4a45b7e4f460f484154b80defe06` (2026-11-18)**. Local patches were installed 2026-11-23. **The current Mac GDScript, JSON, MP3, PNG/WebP assets are not proven to be in GitHub**. The handoff must not be mistaken for synchronization of those files.
- The user explicitly requested a GitHub handoff to the next chat. This document reports known files and behavior, not a verified current-local tree.
- Do not rewrite unrelated minigames, scenes, saves, `Main.gd`, other chapters, or GitHub `main` without necessity.

## User-observed regression — reproduce FIRST

On **Russian** CH01, immediately after completing the puzzle:
1. Mika says “Здравствуйте…” while camera stays on Mika.
2. Female spaceport worker **starts speaking**, but camera only begins to pan to her **after she has already spoken part of her line**.
3. Similar misalignment repeats for remaining lines; Mika's separate thought “Эх… А вдруг я так и не найду дорогу домой?” was heard while camera was still showing the wrong picture.
4. English and other language timings were also reported problematic.
5. Pages 1–4 are required, but page 1 initially worked; biggest regression begins after puzzle / spaceport conversation.

**Absolute contract for EVERY line in EVERY locale:**
`PREVIOUS_VOICE_FINISH → CAMERA_MOVE_START → CAMERA_MOVE_END → FRAME_RENDER_CONFIRMED → VOICE_START → VOICE_FINISH → NEXT_CAMERA_MOVE`.
A line must **never** start while camera is moving or before camera motion begins. Camera remains stable for the entire line, including two speakers in one illustration. Do not silently tolerate overlap.

## Production assets / patch sequence assembled in conversation

Four comic pages, six language variants: `ru, en, pt_BR, es, fr, de`; **32 Line IDs per locale / 192 individual voice MP3s**. Master audio exists for P01–P04 × 6 locales. SVG/PNG/WebP localized pages exist. Scripts and manifests are described below.

Patches created and reportedly installed in the local Mac (installer success is NOT proof of in-game success):
- CH01 P01 integration variants through P01 v1.2;
- P02 six-language cinematic integration;
- P03 six-language cinematic integration;
- post-game sync v1.2, P03 v1.3, P03/P04 all-language v1.4 (abandon these absolute-time camera patches);
- `MIKA_CH01_P01_P04_Modular_6LANG_v2_0.zip` — adds 192 voice clips and 24 `ch01_segments/<locale>/ch01_pXX.json` and modular bridge;
- `MIKA_CH01_P01_P04_Camera_First_192_Clips_v2_1.zip` — 24 `ch01_timeline/<locale>/ch01_pXX.json`, 18 transition SFX, modified scripts `mika_motion_comic/scripts/ch01_modular_bridge_core.gd`, `single_page_comic_intro.gd`, `story_page_two_panels.gd`;
- `MIKA_CH01_P03_Speaker_Cut_Camera_Guard_v2_2.zip` — updates **12 clips** (P03 L001 & L002 for 6 locales), 12 P03 `ch01_segments/ch01_timeline` JSONs, `ch01_modular_bridge_core.gd`; adds `mika_motion_comic/scenes/CH01_PostPuzzle_RU_Sync_Test.tscn` and `mika_motion_comic/scripts/ch01_camera_sync_ru_test.gd`.

The conversation's installers worked at file level, but **actual gameplay still failed**. Do not claim code was fixed. Asset list must be verified against the Mac working directory and Git status. Some chapter code exists only on the Mac and is not present in remote `develop`.

## Specific slicing warning (P03 after puzzle)

Earlier `v2.0/v2.1` split `CH01_P03_L001` after the next speaker had begun (first clip included start of L002). `v2.2` attempted to replace those boundaries:

| Locale | Old boundary (s) | v2.2 boundary (s) |
| --- | ---: | ---: |
| ru | 5.965 | 4.625 |
| en | 5.455 | 4.182 |
| pt_BR | 5.695 | 4.660 |
| es | 5.925 | 3.965 |
| fr | 5.765 | 4.555 |
| de | 6.635 | 4.830 |

Even with this patch, user reported remaining lines out of sync. **All 192 clips need actual listening/content verification**, not waveform-only silence detection. Separate voice and camera causes need to be distinguished via logs.

## Relevant files on local Mac (if v2.0–v2.2 installed)

- `mika_motion_comic/scripts/ch01_modular_bridge_core.gd`
- `mika_motion_comic/scripts/story_page_two_panels.gd`
- `mika_motion_comic/scripts/single_page_comic_intro.gd`
- `mika_motion_comic/scripts/ch01_camera_sync_ru_test.gd`
- `mika_motion_comic/scenes/CH01_PostPuzzle_RU_Sync_Test.tscn`
- `mika_motion_comic/ch01_clips/<locale>/CH01_P0X_LNNN_<locale>.mp3`
- `mika_motion_comic/ch01_segments/<locale>/ch01_p0X.json`
- `mika_motion_comic/ch01_timeline/<locale>/ch01_p0X.json`
- `mika_motion_comic/ch01_camera_sfx/CH01_P0X_LNNN_camera.mp3`
- page art/overlays and original masters under `mika_motion_comic` as installed; inspect actual tree.
- Test event log: `user://ch01_camera_voice_v22.log` (path resolves to Godot app user data directory).
- Standalone test scene: `res://mika_motion_comic/scenes/CH01_PostPuzzle_RU_Sync_Test.tscn` (run via F6 in editor). This does not prove that normal story routing uses the same player.

## Root-cause hypotheses to VERIFY, not assume

- Multiple active AudioStreamPlayers (old long master track and individual clips);
- Parent/child update timing and old absolute clocks still affecting the visible camera;
- A clip containing the next speaker's words;
- Different scene/script instance used in normal storyline vs standalone diagnostic;
- Actual camera shader parameter or update not applied to the rendered view;
- Wrong project copy launched in Godot.

## Next-chat implementation requirement

1. **Get current Mac source** — not GitHub HEAD alone; before editing, inspect `git status` and exact live scene/node connections.
2. Build **one state machine / sequencer** for `CAMERA_MOVING → FRAME_READY → VOICE_PLAYING → WAIT_VOICE_FINISHED → NEXT`. Explicitly disable all previous master-MP3 and competing timing paths. Do not produce another per-line timestamp patch.
3. Test Russian first for all P01–P04 and the P03 spaceport exchange immediately post-puzzle, then remaining 5 locales.
4. Log `VOICE_END`, `CAMERA_START`, `CAMERA_END`, `FRAME_CONFIRMED`, `VOICE_START` with page/locale/Line ID, scene and node path, monotonic time; assert illegal overlaps.
5. Preserve gameplay gates: puzzle (P02→P03), Launch, MARS tracing (P04), and saves.
6. Safe patch with `install.py --check/--install`, backups, conflict abort; **actual in-Godot verification required** before calling done.

## Git synchronization limitation

At document creation, GitHub connector could update repository text but could **not read the live Mac filesystem**. To transfer actual local code and all MP3/assets, the Mac must push the current `InfiniteSpace_Develop` working tree to a new Git branch after reviewing `git status`. Keep `main` and `develop` code unchanged until review; see accompanying GitHub issue for safe sync instructions.

Suggested branch: `handoff/ch01-camera-voice-20261123`, created on the **Mac from its currently checked-out commit**, then only stage the intended `mika_motion_comic` subtree and any relevant adapter scripts. Check for file sizes over GitHub's limits, untracked backups and secrets before push.

**Final note:** Previous assistant said v2.2 fixed the first transition. User reports the overall conversation remains unsynchronized. Treat current code as debugging evidence, not approved solution.

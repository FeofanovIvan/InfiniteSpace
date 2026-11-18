# InfiniteSpace MVP → main migration handoff

Last updated: 2026-11-18 (America/Sao_Paulo)

## Objective and scope

Consolidate the tested InfiniteSpace MVP into `main` while preserving unique `main` atlas/documentation work and selected uncommitted local fixes. The experimental story runtime is explicitly excluded; startup must remain Free World.

## Source state

- `origin/main`: `bea02f18bd31db305bb464eaa20c1d7164a9962f`
- `origin/refactor/unified-learning-20261110`: `dbdb620b65a6ce31d1c3692397ed1f699adae468`
- `origin/feature/story-comic-runtime-20261118`: `900d531c1b327b084db19ca69e570687ec3d5c77` (audited only; excluded from MVP)
- Local story worktree: `d37f6e3fca1f85c84d8dd139b1e96171c6ae6b56` (behind remote; untouched)
- Common ancestor of `main` and refactor: `c577c565b0590764ecd36567f4ecf6872031cd31`
- Divergence at audit: 55 commits unique to `main`, 13 commits unique to refactor.

## Safety backup

The original dirty worktree was not modified. Its 22 tracked changes and all Git-visible untracked files were backed up outside the repository at:

`/Users/ivanfeofanov/Projects/InfiniteSpace/InfiniteSpace_Backups/MVP_MAIN_premerge_20261118_1218`

Backup contents include `working-tree.patch`, `index.patch`, `tracked-files.tar`, `untracked-files.tar`, `status.txt`, and `HEAD.txt`. SHA-256 checksums were recorded in the execution log and verified after copying from `/private/tmp`.

Key backup SHA-256 values:

- `working-tree.patch`: `acbc384fd48617870a4dfe8e7427addfdf3a3784c6fa1ce38d97712e29a49a16`
- `tracked-files.tar`: `3fe1911fba5e40848afac2423540d9dfe0ee9d9cb52a5ba90790646db4f8d888`
- `untracked-files.tar`: `597a92d1d8564f18dd7c2e4ae271db735cfb22d92b7b6f85e13c794ac0155f76`

## Integration worktree

- Path: `/Users/ivanfeofanov/Projects/InfiniteSpace/MVP_MAIN_Integration_20261118`
- Branch: `integration/mvp-main-20261118`
- Base: current `origin/main`
- Merge source: `origin/refactor/unified-learning-20261110`

## Integration commits

- `9dfa6010` — merge `origin/refactor/unified-learning-20261110` into the `main`-based integration branch.
- `321b38e1` — apply the reviewed local gameplay polish while excluding payment/store work.

## Conflict decisions

- `scripts/NpcTraffic.gd`: use the complete refactor v47 jump-heading implementation. The shorter `main` side does not define `jump_heading` and `heading_error`, although both are consumed immediately afterward.
- `atlas/world_atlas.json`: preserve the richer canonical `main` metadata and add refactor runtime fields such as `inhabited`, station assets/placement/accessibility, and other missing keys. Prefer refactor `landing` values because the MVP requires the current all-planets landing behavior. Prefer refactor Crossroads runtime status/note while retaining `main` lore metadata. Story runtime code remains excluded.

## Local changes review

Selected gameplay changes were applied cleanly on top of the merge:

- Matching Pairs, Pizza Fractions, Roll the Ball
- Dinosaur Eggs and Evolution Timeline
- Electric Impulses, Gravity Pinball, Magnetic Collector
- Neural Math and Space Rebus
- Space Racing fleet-facing correction and six-language campaign UI
- `.gitignore` entry for generated `android/`

These changes reuse the already tracked shared `ActionFeedbackVoice.gd` implementation and do not add backup copies.

Intentionally left only in the safety backup:

- Google Play Billing relocation/binaries and the subscription-to-permanent-purchase rewrite
- Android store release preset that activates the billing plugin
- purchase/subscription overlay, access-service, purchase-localization, and settings-link edits tied to that store change
- Google Play listing/legal artwork and documents
- `bubble_backups`, `learning_backups`, and `planet_hub_backups`

Reason: the MVP task explicitly excludes introducing a new payment mechanism without necessity. Backup directories and store-publication artifacts are not runtime sources. The original dirty worktree remains untouched, so this decision is reversible from the recorded patch/archive.

## Verification completed

- Godot `4.7.1.stable.official.a13da4feb` headless editor import: pass, with no project parser or missing-resource errors. Sandbox-only CA/editor-settings/ADB warnings do not reproduce as project failures.
- Normal main scene startup (`res://scenes/main.tscn`) for 600 frames outside the filesystem sandbox: pass. Only forced-quit ObjectDB/resource leak diagnostics remain.
- Normal graphical launch through `run_mvp_mac.command`: pass. The Godot debug window opened with the expected Free World space view, ship, HUD, minimap, and action controls; it was closed cleanly after inspection.
- Existing smoke scripts: all pass — adaptive music, minimap/station, mobile performance, dialogue i18n/adaptive (all six languages), typing tolerance, dialogue UI runtime, Crossroads content, and single-page comic.
- Added `tools/mvp_scene_smoke.gd`: pass. It verifies the real Free World wrapper, exactly 10 initial games, all 24 expanded planet/additional games, launch/return for every registered game, the current Bubble Care scene, and Space Racing.
- Resource reachability audit: 1,368 reachable resources and 2,499 conservative unreferenced candidates. No deletion was performed because many candidates can be loaded dynamically.
- Android debug export: pass after renaming a Bubble background helper that conflicts with Godot 4.7.1's new native `CanvasItem.draw_ellipse` method. Output `/private/tmp/InfiniteSpace-MVP-debug.apk` is 122 MiB, SHA-256 `770aa254b4f2ebc9457c1c7768e7fcca6e8af1b344d169aef6c3e7e8ae5cc7cd`, and verifies with APK Signature Schemes v2 and v3.
- iOS project-only export: pass. Godot generated `/private/tmp/InfiniteSpace-MVP-ios.xcodeproj` and its supporting project/framework directories. `xcodebuild -list` passes. The default arm64 simulator link does not match the object composition in the Godot 4.7.1 simulator archive; an explicit x86_64 simulator build with `CODE_SIGNING_ALLOWED=NO` completes with `BUILD SUCCEEDED`. A device/App Store build cannot be signed locally because no Apple signing identity is installed.

The active startup path remains Free World. Bubble uses `res://bubble/scenes/care_room_actions_camera.tscn`; the old Bubble prototype is not selected. The experimental story branch was audited only and was not merged.

## Local launch

From Finder, double-click `run_mvp_mac.command`, or run:

```sh
cd /Users/ivanfeofanov/Projects/InfiniteSpace/MVP_MAIN_Integration_20261118
./run_mvp_mac.command
```

The launcher pins the project to `/Applications/Godot 4.7.1.app`.

## Next exact action

Open the pull request against `main` and wait for the user's visual approval. Do not merge the pull request before that approval.

## Resume commands

```sh
cd /Users/ivanfeofanov/Projects/InfiniteSpace/MVP_MAIN_Integration_20261118
git status --short
git diff --name-only --diff-filter=U
```

Pull request: `https://github.com/FeofanovIvan/InfiniteSpace/pull/13`. It targets `main` from `integration/mvp-main-20261118`. Do not merge it until the user visually approves the runnable MVP.

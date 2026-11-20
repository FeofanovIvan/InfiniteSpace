# InfiniteSpace Android closed-test handoff

Last updated: 2026-11-19 (America/Sao_Paulo)

## Scope and safety

- MVP source commit: `f2d796681e5105c759aa918b68dc9c8c296046bd`
- MVP pull request: `https://github.com/FeofanovIvan/InfiniteSpace/pull/13` (unchanged; still awaiting visual approval)
- Android release branch: `release/android-closed-test-20261119`
- Android release worktree: `/Users/ivanfeofanov/Projects/InfiniteSpace/Android_Release_20261119`
- Signed release source commit: `0bd54dd055cfc7444b0a40c4bd64693fcb38b948`
- Payment source worktree: `/Users/ivanfeofanov/Projects/InfiniteSpace/InfiniteSpace_Godot` at `dbdb620b65a6ce31d1c3692397ed1f699adae468` plus local changes
- Experimental story branch is not included.

The payment source was backed up before transfer at:

`/Users/ivanfeofanov/Projects/InfiniteSpace/InfiniteSpace_Backups/AndroidRelease_source_20261118_1300`

Backup SHA-256:

- `working-tree.patch`: `acbc384fd48617870a4dfe8e7427addfdf3a3784c6fa1ce38d97712e29a49a16`
- `index.patch`: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852`
- `tracked-files.tar`: `3fe1911f9e7cd80c626355e1789d94facd5b69b099d40f4c301935cf90023c7c`
- `untracked-files.tar`: `597a92d1af754ca106a68aae9bd2c9cc46dec985822502ab28572464770bc345`

## Transfer decisions

Transferred from the local payment work:

- Google Play Billing plugin wrapper and AARs under `addons/GodotGooglePlayBilling/`
- Android one-time purchase logic for `full_game_unlock`
- 600-second active-play limit and persistent local timer state
- parent-gated purchase/restore UI and six-language strings
- Android AAB export preset for `0.36.0 (36)`, package `com.feofanov.infinitespace`, target SDK 36
- Google Play listing, closed-test, data-safety, legal, and approved graphic assets under `docs/google_play/`

Not transferred:

- gameplay files already present in the consolidated MVP
- local backup directories
- experimental story work
- any keystore, password, or signing secret

The local draft attempted to replace iOS subscriptions with a one-time product. That part was rejected because this task is Android-only. The existing iOS product identifiers and dormant subscription implementation remain unchanged.

## Corrections made during review

- Removed the old duplicate plugin path `learning/addons/GodotGooglePlayBilling/`; the supported plugin now lives only at the project root.
- Billing dependency is `com.android.billingclient:billing-ktx:9.1.0`.
- Android queries and restores use product type `INAPP`, never `SUBS`.
- Purchase cancellation now restores the UI instead of leaving the purchase button disabled.
- `PENDING` never grants access.
- A `PURCHASED` item grants access only after Google Play confirms acknowledge; the app then re-queries purchases.
- `ITEM_ALREADY_OWNED` triggers a purchase re-query instead of granting access from the button press.
- The 10-minute gate starts automatically only in Android release builds. Debug builds remain unlocked; iOS runtime behavior is not changed.
- The release preset no longer excludes Neural Math voice/effect files or the encyclopedia asset set. Those paths are dynamically referenced and the old exclusion was unsafe.
- Added the missing `Master`, `Music`, `SFX`, and `VOICE` audio-bus layout and normalized two `Voice` assignments to `VOICE`.
- Added a persistent 0–100 master-volume control to Settings. It controls music, effects, recorded voice, and system TTS and is localized in all six UI languages.

## Current verification status

Completed on Godot 4.7.1:

- full project import/parser check: PASS
- `tools/android_release_billing_smoke.gd`: PASS (exit 0)
  - exact one-time product ID `full_game_unlock` and `INAPP` flow
  - Play-provided localized price and purchase option
  - cancel, pending, offline/error, already-owned restore, and empty-purchase paths
  - acknowledgement followed by verified re-query before permanent entitlement
  - exactly 600 seconds of active gameplay; background and paused time excluded
  - permanent entitlement disables the timer
  - parent-gated purchase/restore UI and strings in `ru`, `en`, `pt`, `es`, `de`, and `fr`
- `tools/mvp_scene_smoke.gd`: PASS (exit 0)
  - 10/10 main games and 24/24 additional games resolve, launch, and return through the real simulator wrapper
  - Free World initially shows ten cards and expands all additional cards
  - Bubble Care launches/returns; Space Racing launches
  - the smoke now uses a test-only Free World mode override and never reads or changes the player's saved mode
- `tools/android_release_persistence_smoke.gd`: PASS (exit 0)
  - crystals/coins, mini-game progress, selected character, flight position, Bubble ownership, and stock survive reload
  - elapsed preview time and locally cached verified entitlement survive an offline restart
  - the test restores pre-existing `user://` save files byte-for-byte
- `planet_hub/tests/mobile_performance_smoke.gd`: PASS (exit 0)
  - Crossroads and Bubble low-GPU paths engage and recover without rebuilding scenes
- `tools/android_release_mobile_layout_smoke.gd`: PASS (exit 0)
  - Settings, volume, purchase gate, simulator, Bubble controls, and Space Racing controls stay inside the logical viewport at 1280×720, 1200×540 (20:9), and 960×720 (4:3)
- `planet_hub/tests/adaptive_music_smoke.gd`: PASS (exit 0)
- `tools/android_release_audio_smoke.gd`: PASS (exit 0)
  - Singularity Action and Calm loop and switch without overlap
  - Bubble Care and Space Racing use dedicated looping music, silence exploration music, and restore the prior context on exit
  - all recorded instructions actually called by the current game resolve in `ru`, `en`, `pt`, `es`, `de`, and `fr`; shapes, numbers 0–10, and plus/minus voices also resolve
  - master-volume control affects all buses and system TTS
- `tools/android_release_game_audio_inventory.gd`: PASS (exit 0)
  - all 34 game scenes launched through the production wrapper
  - every runtime audio player used a valid bus and no scene started more than one background track
- Android Gradle dependency resolution with export-plugin parameters: PASS
  - direct external product dependency is `com.android.billingclient:billing-ktx:9.1.0`
  - no advertising, Appsflyer, or Meta SDK is present
  - Billing 9.1.0 brings Google Data Transport, Play Services Base/Tasks/Location, and `firebase-encoders` transitively; these do not add location, advertising-ID, camera, microphone, or storage permissions to the merged manifest
- precompiled billing AAR compatibility review: PASS
  - plugin identifies itself as GodotGooglePlayBilling 3.3.0
  - bytecode uses Billing 9 APIs including `PendingPurchasesParams`, `enableAutoServiceReconnection`, and `QueryProductDetailsResult`, rather than relying on removed legacy signatures
- Android merged-manifest audit: PASS
  - package `com.feofanov.infinitespace`, version `0.36.0 (36)`, min SDK 24, target SDK 36, ARM64-only export
  - permissions: `INTERNET`, `com.android.vending.BILLING`, `ACCESS_NETWORK_STATE`, plus the app's own signature-level dynamic-receiver permission
  - absent: `AD_ID`, camera, microphone, location, contacts, and storage/media permissions
- diagnostic AAB export: PASS as a build preflight only
  - bundletool 1.16.0 validates the bundle structure successfully
  - the artifact is intentionally unsigned/debug-exported and is **not** a ready release
- signed release AAB export: PASS
  - exported with `--export-release` and secrets supplied only through Godot environment variables read from macOS Keychain
  - JAR signature verification: PASS (`jar verified`)
  - bundletool 1.16.0 validation: PASS
  - release manifest assertions: PASS; `debuggable=true` is absent
  - package/version/SDK/Billing metadata remain `com.feofanov.infinitespace`, `0.36.0 (36)`, min SDK 24, target SDK 36, Billing 9.1.0

The only smoke-test warnings were expected headless-display messages about the virtual keyboard. They did not affect assertions or the exit code.

## Audio audit

Runtime inventory notation is `players/streams active or loaded at startup`. A deferred stream is normal for an effect that is assigned only after the player taps or completes an action. The simulator intentionally silences the exploration soundtrack so instructions and effects remain clear. Existing music was preserved; no new music was added.

| Scene or game | Music | Effects | Voice | Result |
|---|---|---|---|---|
| Free space flight | Singularity Action, loop | Existing flight/UI effects | No required narration | PASS |
| Calm planet hub/scenes | Singularity Calm, loop | Existing hub/UI effects | Recorded/TTS where requested | PASS |
| Simulator shell | Exploration music intentionally silent | Shared UI service | Per-game recorded/TTS | PASS |
| `sim_01` Trace Letters | Silent | 1/0 deferred | 1/1 | PASS |
| `sim_02` Trace Words | Silent | 1/0 deferred | 1/1 | PASS |
| `sim_03` Build a Word | Silent | 2/0 deferred | 9/1 | PASS |
| `sim_04` Build Shapes | Silent | 1/0 deferred | 1/1 | PASS |
| `sim_05` Draw It | Silent | 1/1 | 1/1 | PASS |
| `sim_06` Pick a Number | Silent | 1/0 deferred | 1/1 plus TTS for 11–20 | PASS |
| `sim_07` Write a Number | Silent | 1/0 deferred | 1/1 plus TTS for 11–20 | PASS |
| `sim_08` Action Cards | Silent | Shared/deferred | Shared instruction service | PASS |
| `sim_09` Where Is It? | Silent | Shared/deferred | Shared instruction service | PASS |
| `sim_10` Color Sort | Silent | 1/0 deferred | Visual/shared instruction | PASS |
| `mw__puzzles` | Silent | 1/0 deferred | 1/1 | PASS |
| `mw__animal_habitat` | Silent | 2/2 | 1/1 | PASS |
| `mw__shopping_list` | Silent | Deferred/shared | 1/1 | PASS |
| `mw__product_count` | Silent | Deferred/shared | 2/1 | PASS |
| `lmc__fungal_paths` | Silent | 4/0 deferred | 1/0 deferred/TTS | PASS |
| `lmc__sunbeam_catcher` | Silent | 1/0 deferred | 1/0 deferred/TTS | PASS |
| `lmc__eco_sort` | Silent | 1/0 deferred | 2/1 | PASS |
| `lmc__fungal_race` | Silent | 2/0 deferred | 1/0 deferred/TTS | PASS |
| `smc__build_molecule` | Own quiet ambient, 1/1 | 1/1 | 1/0 deferred/TTS | PASS |
| `smc__solutions_lab` | Silent | 1/0 deferred | 2/1 | PASS |
| `smc__resource_rush` | Silent | 1/1 | 1/0 deferred/TTS | PASS |
| `smc__icy_planet` | Silent | 1/0 deferred | Visual instruction | PASS |
| `ngc6822__fossil_search` | Silent | Shared/deferred | Visual/TTS instruction | PASS |
| `ngc6822__evolution_order` | Silent | 2/2 | 1/0 deferred/TTS | PASS |
| `ngc6822__dinosaur_eggs` | Silent | 1/0 deferred | 1/0 deferred/TTS | PASS |
| `ngc6822__pizza_fraction` | Silent | Deferred/shared | 2/1 | PASS |
| `m31__roll_ball` | Silent | 4/3 | 2/1 | PASS |
| `m31__magnetic_collector` | Silent | 1/0 deferred | 1/0 deferred/TTS | PASS |
| `m31__gravity_pinball` | Silent | 4/4 | 1/0 deferred/TTS | PASS |
| `m31__electric_pulses` | Silent | 1/1 | 1/0 deferred/TTS | PASS |
| `m33__piano` | Silent; piano notes are gameplay | 13/13 piano-note players | Not required | PASS |
| `m33__matching_pairs` | Silent | 4/4 | 2/1 | PASS |
| `m33__space_rebus` | Silent | 1/0 deferred | 1/0 deferred/TTS | PASS |
| `m33__neural_math` | Silent | 1/0 deferred | 2/1 | PASS |
| Bubble Care | `feel_good_island_loop.ogg`, loop | Shower/feed/water/brush/sleep foley connected | Visual interaction | PASS |
| Space Racing | `neon_sign_race_loop.ogg`, loop | Red/yellow/green countdown cues connected | No required narration | PASS |

The `LanguageService` still contains unused legacy dictionary entries for UI/game intros that have no files. Repository-wide call-site search confirmed those keys are not requested by the current MVP, so no placeholder audio was generated and no music/voice asset was replaced.

## Size audit

| Measurement | Result |
|---|---:|
| Consolidated-MVP control debug APK | about 122 MiB (provided baseline) |
| Source media | 3,624 files, 476.59 MiB |
| Godot imported cache | 133 MiB |
| Project working directory including imports | 655 MiB |
| Diagnostic AAB | 145,986,417 bytes (139.22 MiB) |
| Signed release AAB | 144,767,231 bytes (138.06 MiB) |
| Universal diagnostic APK | 205,568,481 bytes (196.05 MiB) |
| Signed-release bundletool estimated device download | 139,857,931–139,880,013 bytes (133.38–133.40 MiB) |

The AAB and APK are different packaging formats, so the 122 MiB APK baseline is not a direct before/after comparison with the AAB. The bundletool estimate is below Google Play's current 500 MB base-module limit and below the 200 MB threshold at which Play displays its large-download notice.

Resource audit findings:

- 57 exact-duplicate groups; 13.67 MiB is the theoretical upper bound if every duplicate could be removed.
- The largest groups are dynamically selected planet backgrounds (4.10 MiB and 1.85 MiB groups), the shared pet/ball card (0.92 MiB), and assets used by both active encyclopedia implementations.
- 2,713 files (214.84 MiB) have no literal `res://` reference, but many are loaded by catalog, manifest, or dynamically constructed paths; this is not a safe deletion list.
- No old video files or archive/backup files were found in the export scope.
- The release export explicitly excludes reports, docs, tools, build outputs, backups, test scenes, comic/story/prologue material, and unrelated QA/fetch folders.
- No resource was deleted or recompressed without proof of safety. Therefore gameplay/audio quality and content size are unchanged by the audit.

Largest packaged items include the ARM64 Godot library (76.18 MB raw / 25.47 MB compressed), app DEX (8.86 MB raw / 2.99 MB compressed), and the existing Singularity Action/Calm and Space Racing music. Detailed SHA-256 findings are in the ignored local reports `reports/android_release_resource_audit.{md,json}`.

## Signed release artifact

- Path: `/Users/ivanfeofanov/Projects/InfiniteSpace/Android_Release_20261119/builds/android/InfiniteSpace-0.36.0-36-release.aab`
- Size: 144,767,231 bytes (138.06 MiB)
- SHA-256: `f31201e64d32f82620ad914677470da8bd6e8b02fe3580dd562f86333208ea01`
- Source commit: `0bd54dd055cfc7444b0a40c4bd64693fcb38b948`
- JAR signature: PASS
- Bundle validation: PASS
- Upload certificate SHA-256: `1E:EA:EC:C7:BE:91:8B:65:0F:20:EB:4E:75:D7:88:E9:3E:5C:8E:C3:2B:2F:B4:BD:A5:BA:F9:FC:90:1F:B6:45`

This release AAB was uploaded successfully to the Google Play Internal testing track on 2026-11-20 and saved in draft release `36 (0.36.0)`. Google Play accepted versionCode 36, minSdk 24, targetSdk 36, and the ARM64 bundle. Google Play App Signing uses the registered upload certificate to verify uploads and signs generated distribution APKs with Google's app signing key.

## Diagnostic artifact (not final)

- Path: `/Users/ivanfeofanov/Projects/InfiniteSpace/Android_Release_20261119/builds/android/InfiniteSpace-0.36.0-36-diagnostic-debug.aab`
- SHA-256: `1c60bca978afa19dc213873f5f09103f51c7612e6af3035d17b2e90dd654259e`
- Bundle validation: PASS
- JAR signature verification: unsigned

This artifact must not be uploaded. It proves that the Gradle template, billing AAR, dependency graph, asset-pack generation, target SDK, and bundle structure build successfully before the permanent upload key is configured.

## Google Play and legal status

- The app now exists in the `feofanov.br@gmail.com` Play Console developer account as **Kids Learning Games: MIKA** with package `com.feofanov.infinitespace`.
- Play Console app ID: `4972395135945061586`; Internal testing track ID: `4701221321805246883`.
- The app is configured as a game, default language `en-US`, and free to install. Monetization remains the one-time in-app product `full_game_unlock`; the product has not yet been created.
- The signed versionCode 36 AAB was uploaded only to Internal testing and saved as draft release `36 (0.36.0)`. It has not been reviewed/confirmed or rolled out to testers; no tester list or release notes are configured.
- No Production action has been performed.
- The console also shows a separate account-level action to declare trader status by February 2027; the owner must complete that declaration using accurate legal/business information.
- The store-listing assets and copy are prepared under `docs/google_play/`; no approved image was regenerated.
- The selected promotion site is `https://mika.playtownkids.app/`; it returned HTTP 200 on 2026-11-20. The deployed privacy policy at `https://mika.playtownkids.app/privacy/` was verified in Russian and English to cover the website, Android, and iOS, including local storage, Google Play/App Store payments, `full_game_unlock`, no Android subscription, parental verification, retention, and deletion. The privacy URL is saved in Play Console.
- Play Console category/contact metadata is saved: Game / Educational, promotion website `https://mika.playtownkids.app/`, and public contact email `feofanov.br@gmail.com`.
- App content declarations saved on 2026-11-20: no ads, no advertising ID, not a government app, no financial features, and no health features. Play Console reduced the remaining App content actions from nine to five.
- The Sign-in/App access declaration remains intentionally unsaved. The one-time paywall counts as restricted content, and Google requires an always-available free review path to all paid functionality. VersionCode 36 has no reviewer bypass, reusable access code, or account-based pre-unlocked entitlement, so declaring full review access would be inaccurate.
- Google's current help still requires at least 12 testers continuously opted in for 14 days for applicable personal accounts created after 2023-11-13. Uploading an AAB alone does not start or satisfy that requirement.

## Signing state

After explicit owner confirmation, a dedicated RSA-4096 upload key was created on 2026-11-19. It is valid through 2054-04-06.

- Private keystore (local only): `/Users/ivanfeofanov/Library/Application Support/InfiniteSpace/keystores/infinite-space-upload-2026.jks`
- Public certificate: `/Users/ivanfeofanov/Library/Application Support/InfiniteSpace/keystores/infinite-space-upload-2026.pem`
- Alias: `infinite-space-upload`
- Password storage: macOS Keychain, service `InfiniteSpace Google Play Upload Keystore`, account `infinite-space-upload`
- File permissions: private keystore `0600`, parent directory `0700`

The keystore and password are not in the repository, AAB directory, report attachments, or command output. Back up the private keystore and its Keychain credential to the owner's secure encrypted storage before the first upload. The public certificate and fingerprints are safe to register or compare in Play Console.

## Changed areas

- `addons/GodotGooglePlayBilling/` and removal of the duplicate legacy addon path
- `learning/src/core/{billing_service,access_service}.gd`
- `learning/src/screens/subscription_overlay.gd`
- `learning/src/core/localization/language_service.gd`
- `scripts/SettingsLanguagePopup.gd`, `default_bus_layout.tres`, and two corrected `VOICE` bus assignments
- `project.godot` and `export_presets.cfg`
- `tools/android_release_*.gd`, the MVP smoke isolation double, and associated Godot UIDs
- `docs/google_play/` listing, legal, test-plan, 14-day journal template, assets, blockers, data-safety draft, and this handoff

## Required next steps

1. Back up the private upload keystore and Keychain credential to secure encrypted owner-controlled storage.
2. Decide and implement an always-available reviewer-access path for paid content, then upload a new signed versionCode if the app changes and complete the Sign-in/App access declaration.
3. Create/activate `full_game_unlock` as a one-time product with USD 15 base price; complete content rating, target audience, Data safety, and trader/terms declarations; configure license testers.
4. Add the Internal testing tester list, release notes, review the draft, and explicitly confirm rollout only when the owner wants the release available to testers.
5. Do not publish to Production.

The signed AAB is present in a saved Internal testing draft. No Production action has been performed.

## Resume commands

```sh
cd /Users/ivanfeofanov/Projects/InfiniteSpace/Android_Release_20261119
git status --short --branch
/Applications/Godot\ 4.7.1.app/Contents/MacOS/Godot --headless --path . --editor --quit
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH='/Users/ivanfeofanov/Library/Application Support/InfiniteSpace/keystores/infinite-space-upload-2026.jks'
export GODOT_ANDROID_KEYSTORE_RELEASE_USER='infinite-space-upload'
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(security find-generic-password -w -s 'InfiniteSpace Google Play Upload Keystore' -a 'infinite-space-upload')"
/Applications/Godot\ 4.7.1.app/Contents/MacOS/Godot --headless --path . --export-release "Google Play Release (AAB)" builds/android/InfiniteSpace-0.36.0-36-release.aab
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
jarsigner -verify builds/android/InfiniteSpace-0.36.0-36-release.aab
keytool -printcert -jarfile builds/android/InfiniteSpace-0.36.0-36-release.aab
java -jar /private/tmp/bundletool-all-1.16.0.jar validate --bundle=builds/android/InfiniteSpace-0.36.0-36-release.aab
shasum -a 256 builds/android/InfiniteSpace-0.36.0-36-release.aab
```

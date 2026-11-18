# MIKA — chapter 1, pages 1-1 and 1-2: experimental event-based story

Base: `refactor/unified-learning-20261110` at `dbdb620b65a6ce31d1c3692397ed1f699adae468`.
Target story branch: `feature/story-comic-runtime-20261118`.

This branch does **not** enable Story in the public Settings menu. Free World
remains the default. Press **F8** in a Godot debug run to replay the prologue.

## Sequence (no new timings)

1. Keep the existing `SinglePageComicIntro` for page `1-1` exactly as is.
   Its current 71-second internal camera animation is not modified.
2. After the first page finishes, pause on the **top wormhole frame** of `1-2`.
   Tap the frame to continue; no duration is attached to this still.
3. Run the **existing** uncontrolled exit/tumble/approach flight. At the end
   of the existing hover, stop at Earth rather than starting the scale-down.
4. Pause on the **left middle** frame (Mika sees Earth); tap to see the
   **right middle** frame (Mika puts on the simulator). Tap to return to flight.
5. In the same flight HUD, show the **existing** helmet simulator card even
   though the fuel has not run out. Only that card is interactive. It opens
   the same ten-game simulator menu. Visiting a mini-game and returning to
   the menu does not continue the plot.
6. When the player **closes the simulator menu**, continue the **existing**
   Earth landing scale-down (same `NpcTraffic` timings and motion).
7. Show **bottom-left** (Earth descent) then **bottom-right** (Mika on Earth)
   frames of `1-2`, advancing only on taps. The final frame holds until the
   player taps it; then the existing Earth hub opens. No subsequent chapter
   or additional cutscene has been authored.

## Media and behavior

- The source `1-2.pdf` is rendered offline into **one** 2481×3508 JPEG,
  `mika_motion_comic/assets/pages/ch01_p02_story.jpg` (~1.2 MB).
  Godot does not render a PDF at runtime.
- The page uses the existing `single_page_comic.gdshader` with five camera
  locations; it does not create five full-resolution duplicates or a video.
- No new text, audio, transitions, durations, or gameplay rewards are added.
- Existing `EmptyFuelSimulatorCard.gd` continues to trigger only at zero fuel
  in normal Free World. Its Story override is gated by
  `Main._story_simulator_required`, which is reset on skip/complete.
- The story's panel advancement is by click/touch/Space/Enter. Escape or the
  existing skip arrow exits the story to normal flight.

## Manual checks in full project

1. Open with Godot 4.7.1; press F8 in a debug run.
2. Verify page 1, tap the wormhole frame, and wait for the existing animated
   ship to stop beside Earth, without auto-landing.
3. Tap Earth-view and simulator frames, check that the same helmet card
   appears **without emptying the tank**.
4. Enter through the card, open and close a mini-game: the main ten-card menu
   should reappear and **no landing** should start yet.
5. Close the menu: confirm the existing landing and the two remaining frames.
6. Leave the last frame displayed to check the stop-point; tap once more to
   enter the Earth hub. Verify ordinary zero-fuel behavior in Free World.

Automated still-panel test:
`godot --headless --path . --script res://planet_hub/tests/story_page_two_panels_smoke.gd`

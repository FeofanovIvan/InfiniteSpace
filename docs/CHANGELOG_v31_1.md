# v31.1 — Fix player hyperjump stalled at the solar-system rim

## Root cause

In v31 `Main.gd`, the ship's cruise controller applied the braking formula to
`max(0, distance - 82)` and clamped movement to that same offset. The route
could converge to a floating-point distance such as `82.00000000000004`:
`distance <= 82` was false while the velocity had already decayed to zero.
This prevented entering `charge`, so the player never switched to the selected
region. These scenarios were reproducible without running Godot.

## Repair

- Removed the 82-unit artificial stop before the rim.
- Cruising now brakes against the exact exit coordinate (`2500` units from the
  central star) and snaps ONLY when fewer than 12 world units remain.
- At the snap the ship is put on the exact rim, velocity is reset, and the
  original shared NPC charge/dash pipeline starts unchanged.
- Added structured `hyperspace_edge_reached` telemetry including rim radius and
  last snap distance.

## Scope

Only `scripts/Main.gd` changes in game code. The same visuals, planets, intro,
UI and other mechanics from v31 remain unchanged.

## Tests

`python3 tools/check_v31_1.py`

Simulates 90 cruise paths from five ship positions, in six directions, at
30/60/120 FPS. Every path reaches the precise 2500 world-unit boundary
within the time limit. v30/v31 static validation was also rerun.

Godot's graphics/runtime playback still needs confirmation on the user's Mac.

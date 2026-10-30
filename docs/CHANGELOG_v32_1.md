# Infinite Space v32.1 — Fix orbital ring distribution

This is a **targeted patch of v32**, keeping Earth, the Milky Way implementation, the NPC scripts, galaxy travel, controls, intro and planet assets untouched.

## What changed

The v32 implementation incorrectly generated 2–3 ring shells around EACH inhabited world. Instead, v32.1 generates only 2–4 total stations ACROSS EACH extra system:

| System | Total ring stations | Policy |
| --- | ---: | --- |
| Milky Way | Unchanged | All existing MW/Earth rings preserved |
| LMC | 2 | At most 1 ring per inhabited candidate planet |
| SMC | 3 | At most 1 ring per inhabited candidate planet |
| NGC 6822 | 2 | At most 1 ring per inhabited candidate planet |
| M31 | 4 | At most 1 ring per inhabited candidate planet |
| M33 | 3 | At most 1 ring per inhabited candidate planet |
| Crossroads | 0 | Kept unchanged |

Eligible planets come from the existing world atlas (`story` world flag or a city/laboratory reference in their unique-feature text). The selected planet indices, distinct station styles, size and orientation are drawn using a **deterministic RNG seed per system**, so the assignments are varied without changing whenever a player leaves and returns. Four original art variants from `station_overlays/scenes/OrbitalStation_01–04.tscn` are reused. They have back/front layers, and each new ring follows its planet but does not rotate with its globe.

## Moon asset set

No new moon module was received among the accessible attachments for the request. Existing moon sprites and orbit logic are untouched. Do not change lunar assets or pretend that a new set was integrated until it is available.

## Validation

Run `python3 tools/check_v32.py && python3 tools/check_v32_1.py`. Static source and atlas checks only; inspect visuals in Godot F5.

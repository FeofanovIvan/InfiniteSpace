# v0.29 — Player hyperjump now uses the same NPC animation

Base: v0.28, patch-only changes.

- NPCs and Miko share `NpcJumpVisual.gd` for the **exact same charge arc, fast directional trail, flash, cloud and ship enlargement**. Changes to the shared renderer affect both.
- NPC and player both use `HyperjumpMotion.gd` constants, edge radius, dash speed and duration; the route across the star system still completes before charging.
- Player no longer uses the separate cyan tunnel overlay or shrinking/dissolving effect.
- Miko's world-space dash still follows the camera; NPCs are drawn relative to that camera, so the apparent motion through the background differs while the VFX is shared.
- Travel to a new galaxy uses a short invisible transit after the departure dash and a matching dash for the arrival at the destination rim.
- `PlayerJumpFX.gd` draws behind the player ship (z=14 vs ship z=15); the normal ship texture is unchanged.
- HUD, previous working comic intro, landing, atlas scenes and galaxy map untouched.

## Files changed

- scripts/Main.gd
- scripts/NpcTraffic.gd
- scripts/PlayerJumpFX.gd (new)
- scripts/NpcJumpVisual.gd (new)
- tools/check_v29.py (new)

No live Godot renderer was available in the build container. Verify with F5.

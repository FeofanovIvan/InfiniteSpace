# InfiniteSpace v47 — SMC NPC landing, takeoff, nose-first jumps

**Release source branch:** `release/v47-flight-fixes`. Based on complete `release/v46-installed-snapshot` (including native PNG assets).
**Installer ZIP SHA-256:** `a4e41cef6d522470f9595f2b95ccfedd9d4853d127c745b1b3b1728fb9b0e813`

## Changes
- `scripts/ForeignTraffic.gd`: seven native SMC craft of five roles only in SMC. Live world-space ports from `get_navigation_bodies()`; anchored approach, hover, landing, docked dwell, takeoff, depart, cruise, align_jump, charge, dash, hidden wait followed by docking and visible takeoff.
- Two NPCs start docked and two start inbound for immediate visible examples.
- SMC craft artwork points +X; cruise and hyperspace displacement derive from their physical visible +X nose, never sideways.
- `scripts/Main.gd`: player nose -Y smoothly aligns to actual warp direction before outbound jump; both departure and arrival use nose-derived movement.
- `scripts/NpcTraffic.gd`: Solar NPC jump waits for nose alignment before entering dash.
- Original inner lights, motion wakes, ships, ports and M33 effects are retained.

## Verification
- Archive ZIP integrity and SHA-256 validated;
- Atomic install over v46, backup, SHA guards, idempotence and static checks passed;
- Contents of `Main.gd` and `ForeignTraffic.gd` in archive have been checked against GitHub branch by Git blob SHA;
- Godot executable unavailable to test runtime F5; visual checks remain necessary.

Full v47 installation sync command in ZIP publishes an actual installed snapshot as `release/v47-installed-snapshot`; this source branch tracks tested patch source and v46 assets meanwhile.

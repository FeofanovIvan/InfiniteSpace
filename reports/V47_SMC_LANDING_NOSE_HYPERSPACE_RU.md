# InfiniteSpace v47

- SMC: 7 native NPC craft, 5 classes, only `smc`; Solar-style anchored approach, hover, landing/shrink, docked/dwell, takeoff/grow, depart, cruise, directional charge, dash, respawn at a port.
- Two begin docked and two begin inbound to demonstrate animations on first visit.
- Moving planet/station world positions are resampled every frame; docked craft stay attached to the moving port.
- The five SMC artworks face +X; all cruise and dash world movement derives from their actual visible +X nose.
- Solar NPC images face -Y. Jump launch waits for alignment; no sideways dash.
- Main player Miko: angle re-aligns during hyperspace charge, both outgoing and arriving displacement derive from visible -Y nose.
- Existing shaders, glows, motion wakes, unrelated systems and classes retained.

## QA
Automated installer, SHA validation, idempotent installation, rollback, static assertions. Godot binary is unavailable to this environment; real F5 checks must be performed on the user's computer.

## GitHub
This archive is a local patch. The full snapshot sync helper below publishes the **actual installed project** to `release/v47-installed-snapshot` without changing `main`; its result must be verified before claiming full GitHub synchronization.

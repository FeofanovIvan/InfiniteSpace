# v58.1 — Play Town local source + Tarantula station update

- Play Town source is now searched first at `/Users/ivanfeofanov/citysafekids` (`~/citysafekids`), as explicitly supplied by the user. Explicit `PLAYTOWN_SOURCE` overrides discovery.
- All 19 educational game cards and their original resource files are copied only into the InfiniteSpace project. The Play Town source remains unchanged.
- The existing LMC laboratory station `Tarantula` (`res://assets/story/tarantula_lab_ship.png`) is replaced byte-for-byte with user-provided `Biomechanical Fractal Starship Core.png` (1254 × 1254, RGBA transparency), original SHA-256 b639efa725a849c06576a4eb783d4f9f686fb642df91c48dd470288757aaca1c.
- Its scale is changed from 0.24 to 0.294 solely to preserve approximate original on-screen span (1536*0.24 ~= 1254*0.294).
- The old 3 blue thrusters were tied to nozzle positions of the **previous asymmetric sprite** and would appear detached from the new symmetrical model. Their creation was disabled; other object effects, gentle orbit, slow spin, camera logic, names, positions and navigation remain as before.
- GitHub v58.1 full installed snapshot is attempted only after local installation. This ZIP contains the new station PNG; the Play Town source is taken from local `~/citysafekids` (not embedded in ZIP).

Checked: archive integrity, Python installer syntax, transactional rollback on invalid files, copied mock Play Town game resources and archive asset SHA. Actual Godot runtime F5 remains to be verified on Mac.

# InfiniteSpace v48 — Triangulum: original ships + inhabited destinations

Five ships **cut unchanged** via Python connected-components from the provided RGBA collage 1536×1024 (positions TL, TR, ML, MR, bottom):

1. m33_civilian_01.png — standard passenger/civilian shuttle.
2. m33_merchant_02.png — merchant/trading ship.
3. m33_courier_03.png — fast diplomatic courier.
4. m33_patrol_04.png — local security patrol.
5. m33_cargo_05.png — heavy freighter.

No generated or redesigned images. Original RGB and alpha retained; only isolated noise outside each object removed.
SMC and M33 both use existing ForeignTraffic state machine (approach, hover, landing, dock, takeoff, depart, cruise, align_jump, charge, dash).
Each system has its own ship art and roles; no inter-region traffic mixing.

Navigation data: catalog field `inhabited` is explicitly configured for each existing world. Initial flags are deliberately conservative and inferred from *both* existing `story: true` and `landing: "landing"` — a provisional game-design setting, **not proof of real extraterrestrial life**. All existing world stations marked accessible. Future world design can update these flags without code changes. Both HUD destination menu and landing action enforce the same explicit flag; foreign NPC ports read it too. Solar NPC traffic additionally filters its own ports from the same catalog.

Real Godot F5 tests are still required. Static project checks are not a substitute for animation QA.

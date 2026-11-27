extends RefCounted
## Reuse the native v104 per-galaxy card assignments. Fill a small selection
## from real games in the SAME system, never replace every planet with Shopping.

const MAX_GAMES_PER_VISIT: int = 3


static func choose(by_planet: Dictionary, planet_id: String, tutorial_exact: bool, seed: int = -1) -> Array:
	var assigned: Array = by_planet.get(planet_id, [])
	if tutorial_exact or planet_id.begins_with("st_") or assigned.is_empty():
		return assigned.duplicate()
	# Empty uninhabited worlds already have a separate genuine Bubble Ball card.
	# Do not fill these with unrelated games and hide the Bubble interaction.
	if assigned.size() == 1 and str(assigned[0]) == "common__pet_walk":
		return assigned.duplicate()
	var galaxy: String = planet_id.get_slice("_", 0)
	var game_prefix: String = galaxy + "__"
	var pool: Array[String] = []
	for location_id in by_planet.keys():
		if not str(location_id).begins_with(galaxy + "_p"):
			continue
		for id in by_planet[location_id]:
			var game_id: String = str(id)
			if game_id.begins_with(game_prefix) and not pool.has(game_id):
				pool.append(game_id)
	var result: Array = []
	for id in assigned:
		if str(id).begins_with(game_prefix) and not result.has(id):
			result.append(id)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed < 0:
		rng.randomize()
	else:
		rng.seed = seed
	var available: Array[String] = pool.duplicate()
	for used in result:
		available.erase(str(used))
	while result.size() < MAX_GAMES_PER_VISIT and not available.is_empty():
		var pick: int = rng.randi_range(0, available.size() - 1)
		result.append(available[pick])
		available.remove_at(pick)
	return result if not result.is_empty() else assigned.duplicate()

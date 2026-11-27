extends RefCounted
## Access boundary: Story after Mars + Free World; native games stay untouched.
## Billing is not wired. Debug builds may enable a clearly labeled test entitlement
## after passing the parental challenge; production builds ignore that flag.

const StoryProgress: Script = preload("res://scripts/StoryProgress.gd")
const StorySubscriptionDialog: Script = preload("res://scripts/StorySubscriptionDialog.gd")
const StoryParentalGate: Script = preload("res://scripts/StoryParentalGate.gd")
const StoryTestEntitlement: Script = preload("res://scripts/StoryTestEntitlement.gd")
const BILLING_SERVICE_NAME: String = "StorySubscriptionService"
const BEAT_AFTER_MARS: String = "free_prologue_complete"
const PAID_STORY_BEATS: Array[String] = [
	"free_prologue_complete", "station_arrival_panels", "station_hub_list",
	"station_hub_launch", "station_map_lmc", "station_warp_out",
	"station_final_panel", "lmc_arrived",
	# These are in-session scenes AFTER the paid Chapter 2 checkpoint.
	# Keep the original entitlement boundary when the tutorial advances.
	"talos_arrival_panels", "talos_hub_maze", "talos_hub_launch",
	"talos_departure_panel", "talos_departed",
	"molly_arrival_panels", "molly_hub_tree", "molly_final_panel",
	"molly_hub_launch", "molly_departed",
	"lmc_station_arrival_panels", "lmc_station_hub_sunbeam",
	"lmc_station_hub_launch", "lmc_station_departed",
	"lmc_station_map_smc", "lmc_station_warp_smc", "smc_arrived",
	"smc_intro_panels",
	"okea_arrival_panels", "okea_hub_lab", "okea_after_lab_panels",
	"okea_hub_launch", "okea_departure_panel", "okea_departed",
	"cela_arrival_panels", "cela_hub_crystals", "cela_after_crystals_panels",
	"cela_bubble_panels", "cela_hub_launch", "cela_departed",
	"lotus_arrival_panels", "lotus_hub_molecule", "lotus_after_molecule_panels",
	"lotus_hub_launch", "lotus_departure_panel", "lotus_map_barnard",
	"lotus_warp_barnard", "barnard_arrived",
	"barnard_prearrival_panels", "barnard_warp_resume", "barnard_pirate_intercept",
	"barnard_threat_panels", "barnard_pirate_escort", "barnard_pirate_landing",
	"barnard_station_panels", "barnard_station_hub_pizza",
	"barnard_escape_panel", "barnard_station_hub_launch", "barnard_station_departed",
	"archeon_arrival_panels", "archeon_hub_fossils", "archeon_after_fossils_panels",
	"archeon_hub_launch", "archeon_departure_panels", "archeon_departed",
	"runa_arrival_panels", "runa_hub_evolution", "runa_after_evolution_panels",
	"runa_hub_launch", "runa_departed", "runa_map_andromeda",
	"runa_warp_andromeda", "m31_arrived",
	"m33_arrived", "m33_story_preview", "m33_intro_panels", "m33_to_lentis", "m33_lentis_panels", "m33_hub_math", "m33_after_math_panels", "m33_hub_launch", "m33_departed", "m33_station_arrived", "m33_gate_rebus", "m33_gate_exit_panels", "m33_gate_transfer", "m33_crossroads_arrived",
	"crossroads_finale_panels", "crossroads_finale_choice",
	"crossroads_ending1_panels", "crossroads_ending1_returned",
	"crossroads_ending2_panels", "crossroads_ending2_note", "crossroads_ending2_draw", "crossroads_ending2_returned"
]
const REGION_ARCS: Dictionary = {
	"lmc": "galaxy_lmc", "smc": "galaxy_smc", "ngc6822": "galaxy_ngc6822",
	"m31": "galaxy_m31", "m33": "galaxy_m33", "crossroads": "galaxy_crossroads"
}

const FREE_COPY: Dictionary = {
	"ru": {"title_free": "Космические открытия", "station_free": "Станция доступна для посадки и игр. Подписка откроет дополнительные занятия и галактики.", "galaxy": "Другие галактики доступны с подпиской."},
	"en": {"title_free": "Explore more of space", "station_free": "The station and its games are open! A subscription unlocks more activities and galaxies.", "galaxy": "Other galaxies are included with a subscription."},
	"fr": {"title_free": "Explorer l’espace", "station_free": "La station et ses jeux sont accessibles ! L’abonnement débloque d’autres activités et galaxies.", "galaxy": "Les autres galaxies nécessitent un abonnement."},
	"de": {"title_free": "Mehr Weltraum entdecken", "station_free": "Station und Spiele sind offen! Mit einem Abo gibt es weitere Spiele und Galaxien.", "galaxy": "Andere Galaxien sind im Abonnement enthalten."},
	"es": {"title_free": "Explorar el espacio", "station_free": "¡La estación y sus juegos están disponibles! La suscripción abre más actividades y galaxias.", "galaxy": "Otras galaxias están incluidas en la suscripción."},
	"pt_BR": {"title_free": "Explore mais o espaço", "station_free": "A estação e seus jogos estão disponíveis! A assinatura libera mais atividades e galáxias.", "galaxy": "Outras galáxias estão incluídas na assinatura."}
}

const COPY: Dictionary = {
	"ru": {"title": "Продолжение истории", "title_free": "Космические открытия", "station": "Ты нашёл космическую станцию! Чтобы совершить посадку и открыть следующую сюжетную арку, нужна подписка.", "station_free": "Станция доступна для посадки и игр. Подписка откроет дополнительные занятия и галактики.", "game": "Эта игра откроется с подпиской. Три первые игры симулятора и занятия с Бабблом остаются доступными.", "galaxy": "Новые галактики открываются постепенно, по мере прохождения сюжетных арок и при активной подписке.", "buy": "Оформить подписку", "later": "Позже", "unavailable": "Магазин пока не подключён. Покупка не выполнена; прогресс сохранён.", "ok": "Понятно", "fog": "За туманом — будущие сюжетные арки", "locked": "Откроется позже"},
	"en": {"title": "Continue the story", "station": "You found the space station! A subscription is needed to land and continue the next story arc.", "game": "This game is included with a subscription. The first three simulator games and Bubble activities are still free.", "galaxy": "New galaxies become available one story arc at a time with an active subscription.", "buy": "Subscribe", "later": "Not now", "unavailable": "The store is not connected yet. No purchase was made; your progress is safe.", "ok": "Got it", "fog": "Future story arcs lie beyond the mist", "locked": "Unlocks later"},
	"fr": {"title": "Continuer l’histoire", "station": "Tu as trouvé la station spatiale ! Un abonnement est nécessaire pour atterrir et poursuivre l’histoire.", "game": "Ce jeu nécessite un abonnement. Les trois premiers jeux du simulateur et les activités avec Bubble restent gratuits.", "galaxy": "De nouvelles galaxies s’ouvrent progressivement au fil de l’histoire avec un abonnement actif.", "buy": "S’abonner", "later": "Plus tard", "unavailable": "La boutique n’est pas encore connectée. Aucun achat n’a été effectué et ta progression est conservée.", "ok": "Compris", "fog": "Les prochains chapitres sont derrière la brume", "locked": "À débloquer"},
	"de": {"title": "Geschichte fortsetzen", "station": "Du hast die Raumstation gefunden! Zum Landen und Fortsetzen der Geschichte brauchst du ein Abonnement.", "game": "Dieses Spiel ist mit Abonnement verfügbar. Die ersten drei Simulator-Spiele und Bubble-Aktivitäten bleiben kostenlos.", "galaxy": "Neue Galaxien werden mit aktivem Abonnement nach und nach im Verlauf der Geschichte freigeschaltet.", "buy": "Abonnieren", "later": "Später", "unavailable": "Der Shop ist noch nicht verbunden. Es wurde nichts gekauft; dein Fortschritt bleibt erhalten.", "ok": "Verstanden", "fog": "Weitere Geschichten liegen hinter dem Nebel", "locked": "Später freischaltbar"},
	"es": {"title": "Continuar la historia", "station": "¡Has encontrado la estación espacial! Necesitas una suscripción para aterrizar y seguir la historia.", "game": "Este juego requiere una suscripción. Los tres primeros juegos del simulador y las actividades con Bubble siguen siendo gratis.", "galaxy": "Las nuevas galaxias se abren poco a poco al avanzar en la historia con una suscripción activa.", "buy": "Suscribirse", "later": "Más tarde", "unavailable": "La tienda todavía no está conectada. No se ha realizado ninguna compra; tu progreso está guardado.", "ok": "Entendido", "fog": "Las próximas historias están tras la niebla", "locked": "Se abrirá después"},
	"pt_BR": {"title": "Continuar a história", "station": "Você encontrou a estação espacial! É necessária uma assinatura para pousar e continuar a próxima história.", "game": "Este jogo requer uma assinatura. Os três primeiros jogos do simulador e as atividades com Bubble continuam grátis.", "galaxy": "Novas galáxias são liberadas gradualmente ao avançar na história com uma assinatura ativa.", "buy": "Assinar", "later": "Mais tarde", "unavailable": "A loja ainda não está conectada. Nenhuma compra foi feita; seu progresso está salvo.", "ok": "Entendi", "fog": "Os próximos capítulos estão além da névoa", "locked": "Libera depois"}
}

static func word(key: String) -> String:
	var language: String = str(MobileLocale.language)
	if StoryProgress.read_mode() == "free_world":
		var free_words: Dictionary = FREE_COPY.get(language, FREE_COPY["en"])
		if free_words.has(key):
			return str(free_words[key])
	var words: Dictionary = COPY.get(language, COPY["en"])
	return str(words.get(key, COPY["en"].get(key, "")))


static func _service() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(BILLING_SERVICE_NAME) if tree != null else null


static func has_verified_subscription() -> bool:
	if StoryTestEntitlement.is_active():
		return true
	var service: Node = _service()
	return service != null and service.has_method("has_verified_subscription") and bool(service.call("has_verified_subscription"))


static func after_free_prologue() -> bool:
	# Keep the paywall active throughout the station and hyperspace lesson.
	return StoryProgress.read_mode() == "story" and PAID_STORY_BEATS.has(StoryProgress.read_beat()) and StoryProgress.story_bubble_joined()


static func paywall_active() -> bool:
	return (StoryProgress.read_mode() == "free_world" or after_free_prologue()) and not has_verified_subscription()


static func can_enter_station() -> bool:
	# Free World never has a storyline checkpoint at the station.
	return StoryProgress.read_mode() == "free_world" or not paywall_active()


static func can_open_region(region_id: String) -> bool:
	if region_id == "mw":
		return true
	if StoryProgress.read_mode() == "free_world":
		return has_verified_subscription()
	# In Story, subscription and an unlocked arc are BOTH necessary.
	# Unknown/unreleased arcs stay covered rather than becoming available by mistake.
	if not has_verified_subscription():
		return false
	if region_id == "lmc":
		return StoryProgress.is_region_unlocked("lmc")
	if region_id == "smc":
		return StoryProgress.is_region_unlocked("smc")
	if region_id == "ngc6822":
		return StoryProgress.is_region_unlocked("ngc6822")
	if region_id == "m31":
		return StoryProgress.is_region_unlocked("m31")
	# Chapter 5 -> Triangulum: same persisted unlock check as previous galaxies.
	# The unfinished galaxy_m33 story arc must not hide an unlocked destination.
	if region_id == "m33":
		return StoryProgress.is_region_unlocked("m33")
	if region_id == "crossroads":
		return StoryProgress.is_region_unlocked("crossroads")
	var arc_id: String = str(REGION_ARCS.get(region_id, ""))
	return not arc_id.is_empty() and StoryProgress.is_unlocked(arc_id)


static func show_notice(owner: Node, reason: String = "station") -> void:
	if owner == null or not owner.is_inside_tree():
		return
	var active: Node = owner.get_node_or_null("StorySubscriptionNotice")
	if is_instance_valid(active):
		return
	var popup: CanvasLayer = StorySubscriptionDialog.new() as CanvasLayer
	popup.name = "StorySubscriptionNotice"
	owner.add_child(popup)
	var free_world: bool = StoryProgress.read_mode() == "free_world"
	var title: String = word("title_free") if free_world else word("title")
	var message_key: String = reason if ["station", "game", "galaxy"].has(reason) else "station"
	if free_world and message_key == "station":
		message_key = "station_free"
	popup.call("configure", title, word(message_key), word("buy"), word("later"))
	popup.connect("subscribe_requested", _request_subscription.bind(owner))
	popup.connect("dismissed", popup.queue_free)


static func _request_subscription(owner: Node) -> void:
	var popup: CanvasLayer = owner.get_node_or_null("StorySubscriptionNotice") as CanvasLayer
	if popup != null:
		popup.queue_free()
	if owner.get_node_or_null("MikaParentalPurchaseGate") != null:
		return
	var parent_gate: CanvasLayer = StoryParentalGate.new() as CanvasLayer
	parent_gate.name = "MikaParentalPurchaseGate"
	owner.add_child(parent_gate)
	parent_gate.connect("dismissed", parent_gate.queue_free)
	parent_gate.connect("completed", parent_gate.queue_free)

# MIKA_CH06_CROSSROADS_GATE_V1

# MIKA_CH07_ENDING_CHOICE_V1

# MIKA_CH08_ENDING_ONE_V1

# MIKA_CH08_ENDING_TWO_V1

extends "res://scripts/StorySubscriptionDialog.gd"
## Parental multiplication check -> informational $15/month plan -> QA switch.
## Neither this screen nor the QA flag performs a real payment.

signal completed

const StoryTestEntitlement: Script = preload("res://scripts/StoryTestEntitlement.gd")

const COPY: Dictionary = {
	"ru": {"parent": "Для родителей", "question": "Взрослый, решите пример: %d × %d = ?", "answer": "Ответ", "check": "Проверить", "cancel": "Назад", "wrong": "Не совсем верно. Попробуйте ещё раз: %d × %d = ?", "plan": "Подписка · $15 / месяц", "plan_info": "План: $15 в месяц. Оплата ещё не подключена, никаких списаний нет. В режиме разработки можно включать тестовый доступ.", "toggle": "Платный доступ · ТЕСТ", "apply": "Применить", "done": "Понятно", "release_info": "План: $15 в месяц. Магазин ещё не подключён. Покупка не совершена."},
	"en": {"parent": "For parents", "question": "Grown-ups: what is %d × %d?", "answer": "Answer", "check": "Check", "cancel": "Back", "wrong": "Try again: %d × %d = ?", "plan": "Subscription · $15 / month", "plan_info": "Plan: $15 per month. Billing isn't connected and nothing is charged. In development you can toggle test access.", "toggle": "Paid access · TEST", "apply": "Apply", "done": "Got it", "release_info": "Plan: $15/month. The store isn't connected. No purchase was made."},
	"fr": {"parent": "Réservé aux parents", "question": "Adultes : combien font %d × %d ?", "answer": "Réponse", "check": "Vérifier", "cancel": "Retour", "wrong": "Réessayez : %d × %d = ?", "plan": "Abonnement · 15 $ / mois", "plan_info": "Tarif : 15 $ par mois. Aucun paiement n'est connecté. En développement, activez l'accès de test.", "toggle": "Accès payant · TEST", "apply": "Appliquer", "done": "Compris", "release_info": "Tarif : 15 $/mois. La boutique n'est pas connectée. Aucun achat effectué."},
	"de": {"parent": "Für Eltern", "question": "Erwachsene: Wie viel ist %d × %d?", "answer": "Antwort", "check": "Prüfen", "cancel": "Zurück", "wrong": "Bitte erneut versuchen: %d × %d = ?", "plan": "Abo · 15 $ / Monat", "plan_info": "Preis: 15 $ monatlich. Keine Bezahlung ist verbunden. In der Entwicklung kann der Testzugang umgeschaltet werden.", "toggle": "Bezahlzugang · TEST", "apply": "Übernehmen", "done": "Verstanden", "release_info": "15 $ pro Monat. Der Shop ist nicht verbunden. Es wurde nichts gekauft."},
	"es": {"parent": "Para adultos", "question": "Adultos: ¿cuánto es %d × %d?", "answer": "Respuesta", "check": "Comprobar", "cancel": "Volver", "wrong": "Inténtalo de nuevo: %d × %d = ?", "plan": "Suscripción · 15 $ / mes", "plan_info": "Plan: 15 $ al mes. No hay pagos conectados ni cargos. En desarrollo puedes activar el acceso de prueba.", "toggle": "Acceso de pago · PRUEBA", "apply": "Aplicar", "done": "Entendido", "release_info": "15 $ al mes. La tienda no está conectada. No se ha comprado nada."},
	"pt_BR": {"parent": "Para responsáveis", "question": "Adulto: quanto é %d × %d?", "answer": "Resposta", "check": "Conferir", "cancel": "Voltar", "wrong": "Tente novamente: %d × %d = ?", "plan": "Assinatura · US$ 15 / mês", "plan_info": "Plano: US$ 15 por mês. Sem cobrança conectada. No desenvolvimento, ative o acesso de teste.", "toggle": "Acesso pago · TESTE", "apply": "Aplicar", "done": "Entendi", "release_info": "US$ 15 por mês. A loja não está conectada. Nenhuma compra foi feita."}
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _number_a: int = 0
var _number_b: int = 0
var _step: String = "challenge"
var _answer_input: LineEdit
var _test_toggle: CheckButton


func _word(key: String) -> String:
	var language: String = str(MobileLocale.language)
	return str(COPY.get(language, COPY["en"]).get(key, COPY["en"].get(key, "")))


func _ready() -> void:
	super._ready()
	layer = 180
	_rng.randomize()
	_answer_input = LineEdit.new()
	_answer_input.name = "ParentMultiplicationAnswer"
	_answer_input.max_length = 3
	_answer_input.placeholder_text = _word("answer")
	_answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_answer_input.add_theme_font_size_override("font_size", 23)
	_answer_input.add_theme_color_override("font_color", Color("ffffff"))
	_answer_input.add_theme_stylebox_override("normal", _button_style(false, false))
	_answer_input.text_submitted.connect(func(_value: String) -> void: _try_answer())
	_panel.add_child(_answer_input)
	_test_toggle = CheckButton.new()
	_test_toggle.name = "DebugOnlyPaidAccessSwitch"
	_test_toggle.text = _word("toggle")
	_test_toggle.add_theme_color_override("font_color", Color("f4c77c"))
	_test_toggle.add_theme_font_size_override("font_size", 17)
	_panel.add_child(_test_toggle)
	_test_toggle.hide()
	subscribe_requested.connect(_action_pressed)
	_new_question()
	_layout()


func _new_question() -> void:
	_number_a = _rng.randi_range(3, 9)
	_number_b = _rng.randi_range(3, 9)
	_title_label.text = _word("parent")
	_body_label.text = _word("question") % [_number_a, _number_b]
	_subscribe_button.text = _word("check")
	_later_button.text = _word("cancel")
	_answer_input.text = ""


func _action_pressed() -> void:
	if _step == "challenge":
		_try_answer()
	elif not StoryTestEntitlement.is_available():
		completed.emit()
	elif StoryTestEntitlement.set_active(_test_toggle.button_pressed):
		completed.emit()


func _try_answer() -> void:
	if _step != "challenge":
		return
	var answer: String = _answer_input.text.strip_edges()
	if not answer.is_valid_int() or int(answer) != _number_a * _number_b:
		_body_label.text = _word("wrong") % [_number_a, _number_b]
		_answer_input.text = ""
		_answer_input.grab_focus()
		return
	_step = "plan"
	_answer_input.hide()
	_title_label.text = _word("plan")
	_body_label.text = _word("plan_info") if StoryTestEntitlement.is_available() else _word("release_info")
	_test_toggle.visible = StoryTestEntitlement.is_available()
	_test_toggle.button_pressed = StoryTestEntitlement.is_active()
	_subscribe_button.text = _word("apply") if StoryTestEntitlement.is_available() else _word("done")
	_layout()


func _layout() -> void:
	super._layout()
	if not is_instance_valid(_answer_input):
		return
	var width: float = _panel.size.x
	var height: float = _panel.size.y
	var safe: Rect2 = MobileLocale.safe_rect(get_viewport().get_visible_rect().size)
	if width < 500.0 and safe.size.y > 520.0:
		# Portrait: let the translated $15 explanation wrap at readable size.
		_panel.size.y = minf(475.0, safe.size.y - 24.0)
		_panel.position = safe.position + (safe.size - _panel.size) * 0.5
		height = _panel.size.y
		var action_y: float = height - 71.0
		_subscribe_button.position.y = action_y
		_later_button.position.y = action_y
	var compact: bool = height < 300.0
	var inset: float = 17.0 if compact else 24.0
	_answer_input.position = Vector2(inset, height - (114.0 if compact else 139.0))
	_answer_input.size = Vector2(minf(215.0, width - inset * 2.0), 45.0)
	_test_toggle.position = Vector2(inset, height - (114.0 if compact else 139.0))
	_test_toggle.size = Vector2(width - inset * 2.0, 50.0)
	_body_label.size.y = maxf(28.0, _answer_input.position.y - _body_label.position.y - 12.0)

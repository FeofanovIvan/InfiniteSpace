extends Node

signal language_changed(locale: String)

const SUPPORTED_LOCALES: Array[String] = ["ru", "en", "pt", "es", "de", "fr"]
const DEFAULT_LOCALE := "en"
const SAVE_PATH := "user://miko_playtown_language.cfg"
const CHARACTER_SELECT_SCENE := "res://education/playtown/scenes/screens/character_select.tscn"
const LANGUAGE_SELECT_SCENE := "res://education/playtown/scenes/screens/language_select.tscn"
const RU_ALPHABET: Array[String] = [
	"А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й",
	"К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф",
	"Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я",
]
const ES_ALPHABET: Array[String] = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "Ñ",
	"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
]
const PT_LETTER_BASES := {
	"Á": "A", "À": "A", "Â": "A", "Ã": "A",
	"É": "E", "Ê": "E",
	"Í": "I",
	"Ó": "O", "Ô": "O", "Õ": "O",
	"Ú": "U", "Ü": "U",
	"Ç": "C",
}
const ES_LETTER_BASES := {
	"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U",
}
const FR_LETTER_BASES := {
	"À": "A", "Â": "A", "Ä": "A", "Ç": "C",
	"É": "E", "È": "E", "Ê": "E", "Ë": "E",
	"Î": "I", "Ï": "I", "Ô": "O", "Ö": "O",
	"Ù": "U", "Û": "U", "Ü": "U", "Ÿ": "Y",
}
const DE_LETTER_BASES := {
	"Ä": "A", "Ö": "O", "Ü": "U", "ẞ": "S", "ß": "S",
}
const LANGUAGE_NAMES := {
	"ru": "Русский",
	"en": "English",
	"pt": "Português",
	"es": "Español",
	"de": "Deutsch",
	"fr": "Français",
}
const UI_TEXT := {
	"choose_language": {
		"ru": "Выбери язык",
		"en": "Choose your language",
		"pt": "Escolha seu idioma",
		"es": "Elige tu idioma",
		"de": "Wähle deine Sprache",
		"fr": "Choisis ta langue",
	},
	"confirm": {
		"ru": "Подтвердить",
		"en": "Confirm",
		"pt": "Confirmar",
		"es": "Confirmar",
		"de": "Bestätigen",
		"fr": "Confirmer",
	},
	"choose_character": {
		"ru": "Выбери персонажа",
		"en": "Choose your character",
		"pt": "Escolha seu personagem",
		"es": "Elige tu personaje",
		"de": "Wähle deine Figur",
		"fr": "Choisis ton personnage",
	},
	"play": {
		"ru": "Играть",
		"en": "Play",
		"pt": "Jogar",
		"es": "Jugar",
		"de": "Spielen",
		"fr": "Jouer",
	},
	"start": {
		"ru": "СТАРТ",
		"en": "START",
		"pt": "INICIAR",
		"es": "INICIAR",
		"de": "START",
		"fr": "DÉPART",
	},
	"buy": {
		"ru": "Купить",
		"en": "Buy",
		"pt": "Comprar",
		"es": "Comprar",
		"de": "Kaufen",
		"fr": "Acheter",
	},
	"back": {
		"ru": "Назад",
		"en": "Back",
		"pt": "Voltar",
		"es": "Atrás",
		"de": "Zurück",
		"fr": "Retour",
	},
	"drag": {
		"ru": "ПЕРЕТАЩИ",
		"en": "DRAG",
		"pt": "ARRASTE",
		"es": "ARRASTRA",
		"de": "ZIEHEN",
		"fr": "GLISSE",
	},
	"owned": {
		"ru": "Куплено",
		"en": "Owned",
		"pt": "Comprado",
		"es": "Comprado",
		"de": "Gekauft",
		"fr": "Acheté",
	},
	"trial": {
		"ru": "ПРОБНЫЙ",
		"en": "TRIAL",
		"pt": "TESTE",
		"es": "PRUEBA",
		"de": "TEST",
		"fr": "ESSAI",
	},
	"included_in_preview": {
		"ru": "Доступно бесплатно",
		"en": "Included in preview",
		"pt": "Disponível no teste",
		"es": "Disponible en la prueba",
		"de": "Im Test verfügbar",
		"fr": "Disponible dans l’essai",
	},
	"race": {
		"ru": "ГОНКА",
		"en": "RACE",
		"pt": "CORRIDA",
		"es": "CARRERA",
		"de": "RENNEN",
		"fr": "COURSE",
	},
	"finish": {
		"ru": "ФИНИШ",
		"en": "FINISH",
		"pt": "CHEGADA",
		"es": "META",
		"de": "ZIEL",
		"fr": "ARRIVÉE",
	},
	"race_finished": {
		"ru": "ФИНИШ!",
		"en": "FINISH!",
		"pt": "CHEGADA!",
		"es": "¡META!",
		"de": "ZIEL!",
		"fr": "ARRIVÉE !",
	},
	"time_up": {
		"ru": "ВРЕМЯ ВЫШЛО!",
		"en": "TIME UP!",
		"pt": "TEMPO ESGOTADO!",
		"es": "¡TIEMPO!",
		"de": "ZEIT UM!",
		"fr": "TEMPS ÉCOULÉ !",
	},
	"great": {
		"ru": "ОТЛИЧНО!",
		"en": "GREAT!",
		"pt": "MUITO BEM!",
		"es": "¡MUY BIEN!",
		"de": "SUPER!",
		"fr": "BRAVO !",
	},
	"again": {
		"ru": "Ещё раз",
		"en": "Again",
		"pt": "De novo",
		"es": "Otra vez",
		"de": "Noch einmal",
		"fr": "Encore",
	},
	"preview_complete_title": {
		"ru": "5 минут закончились", "en": "Your 5 minutes are complete", "pt": "Seus 5 minutos terminaram", "es": "Tus 5 minutos terminaron", "de": "Deine 5 Minuten sind vorbei", "fr": "Tes 5 minutes sont terminées",
	},
	"preview_complete_body": {
		"ru": "Бесплатное время закончилось. Попроси родителей открыть полный доступ к PlayTown.", "en": "The free play period has ended. Ask a parent to continue with full access to PlayTown.", "pt": "O período grátis terminou. Peça a um adulto para liberar o acesso completo ao PlayTown.", "es": "El período gratuito terminó. Pide a un adulto que desbloquee el acceso completo a PlayTown.", "de": "Die kostenlose Spielzeit ist vorbei. Bitte einen Erwachsenen, den vollständigen Zugang zu PlayTown freizuschalten.", "fr": "La période gratuite est terminée. Demande à un adulte de débloquer l’accès complet à PlayTown.",
	},
	"trial_eligible": {
		"ru": "7 дней бесплатно для новых подписчиков", "en": "7 days free for eligible new subscribers", "pt": "7 dias grátis para novos assinantes elegíveis", "es": "7 días gratis para nuevos suscriptores elegibles", "de": "7 Tage kostenlos für berechtigte neue Abonnenten", "fr": "7 jours gratuits pour les nouveaux abonnés éligibles",
	},
	"trial_renewal_notice": {
		"ru": "После пробного периода выбранная подписка продлевается автоматически, пока её не отменят.", "en": "After the free trial, the selected subscription renews automatically unless it is cancelled.", "pt": "Após o período grátis, a assinatura escolhida será renovada automaticamente até ser cancelada.", "es": "Después de la prueba gratuita, la suscripción elegida se renueva automáticamente hasta que se cancele.", "de": "Nach dem Probezeitraum verlängert sich das gewählte Abo automatisch, bis es gekündigt wird.", "fr": "Après l’essai gratuit, l’abonnement choisi est renouvelé automatiquement jusqu’à sa résiliation.",
	},
	"continue": {
		"ru": "Продолжить", "en": "Continue", "pt": "Continuar", "es": "Continuar", "de": "Weiter", "fr": "Continuer",
	},
	"parent_check_hint": {
		"ru": "Родителю нужно пройти быструю проверку", "en": "A parent will need to complete a quick check", "pt": "Um adulto precisa concluir uma verificação rápida", "es": "Un adulto debe completar una comprobación rápida", "de": "Ein Erwachsener muss eine kurze Prüfung lösen", "fr": "Un adulte doit effectuer une vérification rapide",
	},
	"parents_title": {
		"ru": "Для родителей", "en": "For parents", "pt": "Para os pais", "es": "Para padres", "de": "Für Eltern", "fr": "Pour les parents",
	},
	"parents_subtitle": {
		"ru": "Быстрая проверка перед открытием покупок", "en": "A quick check before opening purchases", "pt": "Uma verificação rápida antes de abrir as compras", "es": "Una comprobación rápida antes de abrir las compras", "de": "Eine kurze Prüfung vor dem Öffnen der Käufe", "fr": "Une vérification rapide avant d’ouvrir les achats",
	},
	"enter_answer": {
		"ru": "Введите ответ", "en": "Enter the answer", "pt": "Digite a resposta", "es": "Escribe la respuesta", "de": "Antwort eingeben", "fr": "Saisis la réponse",
	},
	"try_again": {
		"ru": "Попробуйте ещё раз", "en": "Please try again", "pt": "Tente novamente", "es": "Inténtalo de nuevo", "de": "Bitte noch einmal versuchen", "fr": "Réessayez",
	},
	"subscription_title": {
		"ru": "Откройте полную версию", "en": "Unlock the full game", "pt": "Desbloqueie o jogo completo", "es": "Desbloquea el juego completo", "de": "Vollversion freischalten", "fr": "Débloquez le jeu complet",
	},
	"subscription_body": {
		"ru": "Выберите подходящий план для вашей семьи. Новые подписчики могут бесплатно пользоваться полной версией 7 дней.", "en": "Choose the plan that works best for your family. New subscribers can try the full game free for 7 days.", "pt": "Escolha o melhor plano para sua família. Novos assinantes podem testar o jogo completo grátis por 7 dias.", "es": "Elige el plan ideal para tu familia. Los nuevos suscriptores pueden probar el juego completo gratis durante 7 días.", "de": "Wählen Sie den passenden Tarif für Ihre Familie. Neue Abonnenten können das vollständige Spiel 7 Tage kostenlos testen.", "fr": "Choisissez l’offre adaptée à votre famille. Les nouveaux abonnés peuvent essayer le jeu complet gratuitement pendant 7 jours.",
	},
	"subscription_active": {
		"ru": "Подписка активна", "en": "Your subscription is active", "pt": "Sua assinatura está ativa", "es": "Tu suscripción está activa", "de": "Dein Abo ist aktiv", "fr": "Votre abonnement est actif",
	},
	"manage_subscription": {
		"ru": "Управлять подпиской", "en": "Manage subscription", "pt": "Gerenciar assinatura", "es": "Gestionar suscripción", "de": "Abo verwalten", "fr": "Gérer l’abonnement",
	},
	"plan_monthly": {"ru": "Ежемесячно", "en": "Monthly", "pt": "Mensal", "es": "Mensual", "de": "Monatlich", "fr": "Mensuel"},
	"plan_quarterly": {"ru": "3 месяца", "en": "3 months", "pt": "3 meses", "es": "3 meses", "de": "3 Monate", "fr": "3 mois"},
	"plan_annual": {"ru": "На год", "en": "Yearly", "pt": "Anual", "es": "Anual", "de": "Jährlich", "fr": "Annuel"},
	"restore_purchases": {"ru": "Восстановить покупки", "en": "Restore purchases", "pt": "Restaurar compras", "es": "Restaurar compras", "de": "Käufe wiederherstellen", "fr": "Restaurer les achats"},
	"retry_store": {"ru": "Повторить подключение", "en": "Retry store connection", "pt": "Tentar conexão novamente", "es": "Reintentar conexión", "de": "Verbindung erneut versuchen", "fr": "Réessayer la connexion"},
	"back_to_game": {"ru": "Вернуться в игру", "en": "Back to game", "pt": "Voltar ao jogo", "es": "Volver al juego", "de": "Zurück zum Spiel", "fr": "Retour au jeu"},
	"store_connecting": {"ru": "Подключаемся к магазину…", "en": "Connecting to the app store…", "pt": "Conectando à loja…", "es": "Conectando con la tienda…", "de": "Verbindung zum Store…", "fr": "Connexion à la boutique…"},
	"store_opening": {"ru": "Открываем магазин…", "en": "Opening the app store…", "pt": "Abrindo a loja…", "es": "Abriendo la tienda…", "de": "Store wird geöffnet…", "fr": "Ouverture de la boutique…"},
	"store_unavailable": {"ru": "Магазин недоступен. Попробуйте позже.", "en": "The app store is not available. Please try again later.", "pt": "A loja não está disponível. Tente novamente mais tarde.", "es": "La tienda no está disponible. Inténtalo más tarde.", "de": "Der Store ist nicht verfügbar. Bitte später erneut versuchen.", "fr": "La boutique n’est pas disponible. Réessayez plus tard."},
	"restoring_purchases": {"ru": "Восстанавливаем покупки…", "en": "Restoring purchases…", "pt": "Restaurando compras…", "es": "Restaurando compras…", "de": "Käufe werden wiederhergestellt…", "fr": "Restauration des achats…"},
	"purchase_pending": {"ru": "Покупка ожидает подтверждения", "en": "The purchase is pending approval", "pt": "A compra aguarda aprovação", "es": "La compra espera aprobación", "de": "Der Kauf wartet auf Genehmigung", "fr": "L’achat attend une approbation"},
	"select_plan": {"ru": "Выберите план", "en": "Select a plan", "pt": "Escolha um plano", "es": "Elige un plan", "de": "Tarif wählen", "fr": "Choisissez une offre"},
	"trial_seven_days": {"ru": "7 дней бесплатно", "en": "7 days free", "pt": "7 dias grátis", "es": "7 días gratis", "de": "7 Tage kostenlos", "fr": "7 jours gratuits"},
	"trial_free": {"ru": "Бесплатный период", "en": "Free trial", "pt": "Período grátis", "es": "Prueba gratuita", "de": "Kostenlos testen", "fr": "Essai gratuit"},
	"subscriptions_renew": {"ru": "Подписка продлевается автоматически, пока её не отменят в аккаунте магазина.", "en": "Subscriptions renew automatically unless cancelled in your store account.", "pt": "A assinatura é renovada automaticamente até ser cancelada na conta da loja.", "es": "La suscripción se renueva automáticamente hasta que se cancele en la cuenta de la tienda.", "de": "Das Abo verlängert sich automatisch, bis es im Store-Konto gekündigt wird.", "fr": "L’abonnement est renouvelé automatiquement jusqu’à sa résiliation dans le compte de la boutique."},
	"privacy_policy": {"ru": "Политика конфиденциальности", "en": "Privacy Policy", "pt": "Política de Privacidade", "es": "Política de privacidad", "de": "Datenschutzrichtlinie", "fr": "Politique de confidentialité"},
	"terms_of_use": {"ru": "Условия использования", "en": "Terms of Use (EULA)", "pt": "Termos de Uso", "es": "Términos de uso", "de": "Nutzungsbedingungen", "fr": "Conditions d’utilisation"},
	"shopping_list": {"ru": "СПИСОК ПОКУПОК", "en": "SHOPPING LIST", "pt": "LISTA DE COMPRAS", "es": "LISTA DE COMPRAS", "fr": "LISTE DE COURSES", "de": "EINKAUFSLISTE"},
	"well_done": {"ru": "МОЛОДЕЦ!", "en": "WELL DONE!", "pt": "MUITO BEM!", "es": "¡MUY BIEN!", "fr": "BRAVO !", "de": "GUT GEMACHT!"},
	"bought_everything": {"ru": "Ты купил всё!", "en": "You bought everything!", "pt": "Você comprou tudo!", "es": "¡Compraste todo!", "fr": "Tu as tout acheté !", "de": "Du hast alles gekauft!"},
	"product_count_instruction": {"ru": "Добавь продукты с полки или вытащи лишние из корзины.", "en": "Add products from the shelf or remove extras from the basket.", "pt": "Adicione produtos da prateleira ou retire os que sobraram da cesta.", "es": "Añade productos del estante o retira los que sobran de la canasta.", "fr": "Ajoute les produits de l’étagère ou retire ceux en trop du panier.", "de": "Lege Produkte aus dem Regal in den Korb oder nimm überzählige heraus."},
	"product_count_title": {"ru": "Собери количество", "en": "Collect the quantity", "pt": "Complete a quantidade", "es": "Completa la cantidad", "fr": "Complète la quantité", "de": "Vervollständige die Menge"},
	"product_not_listed": {"ru": "Этого продукта нет в списке", "en": "This product is not on the list", "pt": "Este produto não está na lista", "es": "Este producto no está en la lista", "fr": "Ce produit n’est pas sur la liste", "de": "Dieses Produkt steht nicht auf der Liste"},
	"basket_already_five": {"ru": "В корзине уже пять", "en": "There are already five in the basket", "pt": "A cesta já tem cinco", "es": "La canasta ya tiene cinco", "fr": "Il y en a déjà cinq dans le panier", "de": "Im Korb sind schon fünf"},
	"product_count_complete": {"ru": "Отлично! Всё посчитано правильно!", "en": "Great! Everything is counted correctly!", "pt": "Muito bem! Você contou tudo corretamente!", "es": "¡Muy bien! ¡Todo está contado correctamente!", "fr": "Bravo ! Tout est bien compté !", "de": "Super! Alles ist richtig gezählt!"},
	"all_products_correct": {"ru": "Все покупки собраны правильно!", "en": "All products were collected correctly!", "pt": "Todos os produtos foram separados corretamente!", "es": "¡Todos los productos están correctos!", "fr": "Tous les produits sont corrects !", "de": "Alle Produkte sind richtig gesammelt!"},
	"path_try_again": {"ru": "ПОПРОБОВАТЬ ЕЩЁ", "en": "TRY AGAIN", "pt": "TENTE NOVAMENTE", "es": "INTÉNTALO DE NUEVO", "fr": "RÉESSAYER", "de": "NOCH EINMAL"},
	"back_to_games": {"ru": "НАЗАД К ИГРАМ", "en": "BACK TO GAMES", "pt": "VOLTAR AOS JOGOS", "es": "VOLVER A LOS JUEGOS", "fr": "RETOUR AUX JEUX", "de": "ZURÜCK ZU DEN SPIELEN"},
	"path_success_title": {"ru": "УРА! ДРУЖОК ДОМА!", "en": "HOORAY! YOUR FRIEND IS HOME!", "pt": "VIVA! O AMIGUINHO CHEGOU EM CASA!", "es": "¡VIVA! ¡AMIGUITO LLEGÓ A CASA!", "fr": "BRAVO ! PETIT AMI EST CHEZ LUI !", "de": "HURRA! DEIN FREUND IST ZU HAUSE!"},
	"path_success_body": {"ru": "Ты правильно построил маршрут и помог Дружку добраться до домика.", "en": "You built the route correctly and helped your friend reach the house.", "pt": "Você montou o caminho certo e ajudou o Amiguinho a chegar em casa.", "es": "Construiste el camino correcto y ayudaste a Amiguito a llegar a casa.", "fr": "Tu as construit le bon chemin et aidé Petit Ami à rejoindre sa maison.", "de": "Du hast den richtigen Weg gebaut und deinem Freund geholfen, das Haus zu erreichen."},
	"path_fail_title": {"ru": "ДРУЖОК СВЕРНУЛ НЕ ТУДА", "en": "YOUR FRIEND TOOK A WRONG TURN", "pt": "O AMIGUINHO VIROU NO LUGAR ERRADO", "es": "AMIGUITO TOMÓ EL CAMINO EQUIVOCADO", "fr": "PETIT AMI S’EST TROMPÉ DE CHEMIN", "de": "DEIN FREUND IST FALSCH ABGEBOGEN"},
	"path_fail_body": {"ru": "Поставь крестики на лишние дороги и проверь, где должны стоять мосты.", "en": "Place crosses on extra roads and check where the bridges should go.", "pt": "Coloque cruzes nos caminhos errados e veja onde as pontes devem ficar.", "es": "Coloca cruces en los caminos incorrectos y revisa dónde deben ir los puentes.", "fr": "Place des croix sur les mauvais chemins et vérifie où mettre les ponts.", "de": "Setze Kreuze auf die falschen Wege und prüfe, wo die Brücken hingehören."},
}
const TITLE_TEXTURES := {
	"choose_language": {
		"en": "res://education/playtown/assets/ui/localization/en/title_choose_language.webp",
		"ru": "res://education/playtown/assets/ui/language/title_choose_language_ru.webp",
		"pt": "res://education/playtown/assets/ui/localization/pt/title_choose_language.webp",
		"es": "res://education/playtown/assets/ui/localization/es/title_choose_language.webp",
		"fr": "res://education/playtown/assets/ui/localization/fr/title_choose_language.webp",
		"de": "res://education/playtown/assets/ui/localization/de/title_choose_language.webp",
	},
	"choose_character": {
		"en": "res://education/playtown/assets/ui/select/title_choose.png",
		"ru": "res://education/playtown/assets/ui/localization/ru/title_choose_character.webp",
		"pt": "res://education/playtown/assets/ui/localization/pt/title_choose_character.webp",
		"es": "res://education/playtown/assets/ui/localization/es/title_choose_character.webp",
		"fr": "res://education/playtown/assets/ui/localization/fr/title_choose_character.webp",
		"de": "res://education/playtown/assets/ui/localization/de/title_choose_character.webp",
	},
	"choose_game": {
		"en": "res://education/playtown/assets/ui/game_select/title_choose_game.png",
		"ru": "res://education/playtown/assets/ui/localization/ru/title_choose_game.webp",
		"pt": "res://education/playtown/assets/ui/localization/pt/title_choose_game.webp",
		"es": "res://education/playtown/assets/ui/localization/es/title_choose_game.webp",
		"fr": "res://education/playtown/assets/ui/localization/fr/title_choose_game.webp",
		"de": "res://education/playtown/assets/ui/localization/de/title_choose_game.webp",
	},
}
const UI_VOICES := {
	"choose_language": {
		"en": "res://education/playtown/audio/voice/en/ui/choose_language.mp3",
		"ru": "res://education/playtown/audio/voice/ru/ui/choose_language.ogg",
		"pt": "res://education/playtown/audio/voice/pt/ui/choose_language.mp3",
		"es": "res://education/playtown/audio/voice/es/ui/choose_language.mp3",
		"fr": "res://education/playtown/audio/voice/fr/ui/choose_language.mp3",
		"de": "res://education/playtown/audio/voice/de/ui/choose_language.mp3",
	},
	"choose_character": {
		"en": "res://education/playtown/audio/voice/en/ui/choose_character.mp3",
		"ru": "res://education/playtown/audio/voice/ru/ui/choose_character.mp3",
		"pt": "res://education/playtown/audio/voice/pt/ui/choose_character.mp3",
		"es": "res://education/playtown/audio/voice/es/ui/choose_character.mp3",
		"fr": "res://education/playtown/audio/voice/fr/ui/choose_character.mp3",
		"de": "res://education/playtown/audio/voice/de/ui/choose_character.mp3",
	},
	"choose_game": {
		"en": "res://education/playtown/audio/voice/en/ui/choose_game.mp3",
		"ru": "res://education/playtown/audio/voice/ru/ui/choose_game.mp3",
		"pt": "res://education/playtown/audio/voice/pt/ui/choose_game.mp3",
		"es": "res://education/playtown/audio/voice/es/ui/choose_game.mp3",
		"fr": "res://education/playtown/audio/voice/fr/ui/choose_game.mp3",
		"de": "res://education/playtown/audio/voice/de/ui/choose_game.mp3",
	},
	"pet_shop_intro": {
		"en": "res://education/playtown/audio/voice/en/ui/pet_shop_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/ui/pet_shop_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/ui/pet_shop_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/ui/pet_shop_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/ui/pet_shop_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/ui/pet_shop_intro.mp3",
	},
	"parent_gate_intro": {
		"en": "res://education/playtown/audio/voice/en/ui/parent_gate_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/ui/parent_gate_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/ui/parent_gate_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/ui/parent_gate_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/ui/parent_gate_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/ui/parent_gate_intro.mp3",
	},
}
const GAME_VOICES := {
	"puzzle_intro": {
		"en": "res://education/playtown/audio/voice/en/games/puzzle_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/puzzle_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/puzzle_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/puzzle_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/puzzle_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/puzzle_intro.mp3",
	},
	"wardrobe_intro": {
		"en": "res://education/playtown/audio/voice/en/games/wardrobe_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/wardrobe_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/wardrobe_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/wardrobe_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/wardrobe_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/wardrobe_intro.mp3",
	},
	"matching_pairs_intro": {
		"en": "res://education/playtown/audio/voice/en/games/matching_pairs_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/matching_pairs_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/matching_pairs_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/matching_pairs_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/matching_pairs_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/matching_pairs_intro.mp3",
	},
	"animal_habitat_intro": {
		"en": "res://education/playtown/audio/voice/en/games/animal_habitat_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/animal_habitat_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/animal_habitat_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/animal_habitat_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/animal_habitat_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/animal_habitat_intro.mp3",
	},
	"letter_trace_intro": {
		"en": "res://education/playtown/audio/voice/en/games/letter_trace_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/letter_trace_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/letter_trace_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/letter_trace_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/letter_trace_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/letter_trace_intro.mp3",
	},
	"shape_trace_intro": {
		"en": "res://education/playtown/audio/voice/en/games/shape_trace_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/shape_trace_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/shape_trace_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/shape_trace_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/shape_trace_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/shape_trace_intro.mp3",
	},
	"word_build_intro": {
		"en": "res://education/playtown/audio/voice/en/games/word_build_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/word_build_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/word_build_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/word_build_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/word_build_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/word_build_intro.mp3",
	},
	"word_trace_intro": {
		"en": "res://education/playtown/audio/voice/en/games/word_trace_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/word_trace_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/word_trace_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/word_trace_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/word_trace_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/word_trace_intro.mp3",
	},
	"race_intro": {
		"en": "res://education/playtown/audio/voice/en/games/race_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/race_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/race_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/race_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/race_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/race_intro.mp3",
	},
	"tilt_maze_intro": {
		"en": "res://education/playtown/audio/voice/en/games/tilt_maze_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/tilt_maze_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/tilt_maze_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/tilt_maze_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/tilt_maze_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/tilt_maze_intro.mp3",
	},
	"path_builder_intro": {
		"en": "res://education/playtown/audio/voice/en/games/path_builder_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/path_builder_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/path_builder_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/path_builder_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/path_builder_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/path_builder_intro.mp3",
	},
	"count_products_intro": {
		"en": "res://education/playtown/audio/voice/en/games/count_products_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/count_products_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/count_products_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/count_products_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/count_products_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/count_products_intro.mp3",
	},
	"collect_basket_intro": {
		"en": "res://education/playtown/audio/voice/en/games/collect_basket_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/collect_basket_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/collect_basket_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/collect_basket_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/collect_basket_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/collect_basket_intro.mp3",
	},
	"write_product_count_intro": {
		"en": "res://education/playtown/audio/voice/en/games/write_product_count_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/write_product_count_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/write_product_count_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/write_product_count_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/write_product_count_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/write_product_count_intro.mp3",
	},
	"collect_product_count_intro": {
		"en": "res://education/playtown/audio/voice/en/games/collect_product_count_intro.mp3",
		"ru": "res://education/playtown/audio/voice/ru/games/collect_product_count_intro.mp3",
		"pt": "res://education/playtown/audio/voice/pt/games/collect_product_count_intro.mp3",
		"es": "res://education/playtown/audio/voice/es/games/collect_product_count_intro.mp3",
		"fr": "res://education/playtown/audio/voice/fr/games/collect_product_count_intro.mp3",
		"de": "res://education/playtown/audio/voice/de/games/collect_product_count_intro.mp3",
	},
}
const SHAPE_NAMES := {
	"circle": {
		"ru": "КРУГ",
		"en": "CIRCLE",
		"pt": "CÍRCULO",
		"es": "CÍRCULO",
		"fr": "CERCLE",
		"de": "KREIS",
	},
	"square": {
		"ru": "КВАДРАТ",
		"en": "SQUARE",
		"pt": "QUADRADO",
		"es": "CUADRADO",
		"fr": "CARRÉ",
		"de": "QUADRAT",
	},
	"triangle": {
		"ru": "ТРЕУГОЛЬНИК",
		"en": "TRIANGLE",
		"pt": "TRIÂNGULO",
		"es": "TRIÁNGULO",
		"fr": "TRIANGLE",
		"de": "DREIECK",
	},
	"diamond": {
		"ru": "РОМБ",
		"en": "DIAMOND",
		"pt": "LOSANGO",
		"es": "ROMBO",
		"fr": "LOSANGE",
		"de": "RAUTE",
	},
	"star": {
		"ru": "ЗВЕЗДА",
		"en": "STAR",
		"pt": "ESTRELA",
		"es": "ESTRELLA",
		"fr": "ÉTOILE",
		"de": "STERN",
	},
}
const SHAPE_VOICES := {
	"circle": {
		"en": "res://education/playtown/audio/voice/en/shapes/circle.mp3",
		"ru": "res://education/playtown/audio/voice/ru/shapes/circle.mp3",
		"pt": "res://education/playtown/audio/voice/pt/shapes/circle.mp3",
		"es": "res://education/playtown/audio/voice/es/shapes/circle.mp3",
		"fr": "res://education/playtown/audio/voice/fr/shapes/circle.mp3",
		"de": "res://education/playtown/audio/voice/de/shapes/circle.mp3",
	},
	"square": {
		"en": "res://education/playtown/audio/voice/en/shapes/square.mp3",
		"ru": "res://education/playtown/audio/voice/ru/shapes/square.mp3",
		"pt": "res://education/playtown/audio/voice/pt/shapes/square.mp3",
		"es": "res://education/playtown/audio/voice/es/shapes/square.mp3",
		"fr": "res://education/playtown/audio/voice/fr/shapes/square.mp3",
		"de": "res://education/playtown/audio/voice/de/shapes/square.mp3",
	},
	"triangle": {
		"en": "res://education/playtown/audio/voice/en/shapes/triangle.mp3",
		"ru": "res://education/playtown/audio/voice/ru/shapes/triangle.mp3",
		"pt": "res://education/playtown/audio/voice/pt/shapes/triangle.mp3",
		"es": "res://education/playtown/audio/voice/es/shapes/triangle.mp3",
		"fr": "res://education/playtown/audio/voice/fr/shapes/triangle.mp3",
		"de": "res://education/playtown/audio/voice/de/shapes/triangle.mp3",
	},
	"diamond": {
		"en": "res://education/playtown/audio/voice/en/shapes/diamond.mp3",
		"ru": "res://education/playtown/audio/voice/ru/shapes/diamond.mp3",
		"pt": "res://education/playtown/audio/voice/pt/shapes/diamond.mp3",
		"es": "res://education/playtown/audio/voice/es/shapes/diamond.mp3",
		"fr": "res://education/playtown/audio/voice/fr/shapes/diamond.mp3",
		"de": "res://education/playtown/audio/voice/de/shapes/diamond.mp3",
	},
	"star": {
		"en": "res://education/playtown/audio/voice/en/shapes/star.mp3",
		"ru": "res://education/playtown/audio/voice/ru/shapes/star.mp3",
		"pt": "res://education/playtown/audio/voice/pt/shapes/star.mp3",
		"es": "res://education/playtown/audio/voice/es/shapes/star.mp3",
		"fr": "res://education/playtown/audio/voice/fr/shapes/star.mp3",
		"de": "res://education/playtown/audio/voice/de/shapes/star.mp3",
	},
}
const CLOTHING_VOICES := {
	"tshirt_white": {
		"en": "res://education/playtown/audio/voice/en/clothes/tshirt_white.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/tshirt_white.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/tshirt_white.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/tshirt_white.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/tshirt_white.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/tshirt_white.mp3",
	},
	"tshirt_blue": {
		"en": "res://education/playtown/audio/voice/en/clothes/tshirt_blue.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/tshirt_blue.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/tshirt_blue.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/tshirt_blue.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/tshirt_blue.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/tshirt_blue.mp3",
	},
	"tshirt_green": {
		"en": "res://education/playtown/audio/voice/en/clothes/tshirt_yellow.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/tshirt_yellow.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/tshirt_yellow.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/tshirt_yellow.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/tshirt_yellow.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/tshirt_yellow.mp3",
	},
	"tshirt_red": {
		"en": "res://education/playtown/audio/voice/en/clothes/tshirt_black.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/tshirt_black.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/tshirt_black.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/tshirt_black.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/tshirt_black.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/tshirt_black.mp3",
	},
	"shirt_blue": {
		"en": "res://education/playtown/audio/voice/en/clothes/shorts_purple.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/shorts_purple.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/shorts_purple.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/shorts_purple.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/shorts_purple.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/shorts_purple.mp3",
	},
	"skirt_red": {
		"en": "res://education/playtown/audio/voice/en/clothes/skirt_red.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/skirt_red.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/skirt_red.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/skirt_red.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/skirt_red.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/skirt_red.mp3",
	},
	"shirt_green": {
		"en": "res://education/playtown/audio/voice/en/clothes/shorts_green.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/shorts_green.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/shorts_green.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/shorts_green.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/shorts_green.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/shorts_green.mp3",
	},
	"skirt_blue": {
		"en": "res://education/playtown/audio/voice/en/clothes/skirt_purple.mp3",
		"ru": "res://education/playtown/audio/voice/ru/clothes/skirt_purple.mp3",
		"pt": "res://education/playtown/audio/voice/pt/clothes/skirt_purple.mp3",
		"es": "res://education/playtown/audio/voice/es/clothes/skirt_purple.mp3",
		"fr": "res://education/playtown/audio/voice/fr/clothes/skirt_purple.mp3",
		"de": "res://education/playtown/audio/voice/de/clothes/skirt_purple.mp3",
	},
}
const WORLD_VOICES := {
	"classmate": {
		"en": "res://education/playtown/audio/voice/en/world/classmate.mp3",
		"ru": "res://education/playtown/audio/voice/ru/world/classmate.mp3",
		"pt": "res://education/playtown/audio/voice/pt/world/classmate.mp3",
		"es": "res://education/playtown/audio/voice/es/world/classmate.mp3",
		"fr": "res://education/playtown/audio/voice/fr/world/classmate.mp3",
		"de": "res://education/playtown/audio/voice/de/world/classmate.mp3",
	},
	"mom": {
		"en": "res://education/playtown/audio/voice/en/world/mom.mp3",
		"ru": "res://education/playtown/audio/voice/ru/world/mom.mp3",
		"pt": "res://education/playtown/audio/voice/pt/world/mom.mp3",
		"es": "res://education/playtown/audio/voice/es/world/mom.mp3",
		"fr": "res://education/playtown/audio/voice/fr/world/mom.mp3",
		"de": "res://education/playtown/audio/voice/de/world/mom.mp3",
	},
	"teacher": {
		"en": "res://education/playtown/audio/voice/en/world/teacher.mp3",
		"ru": "res://education/playtown/audio/voice/ru/world/teacher.mp3",
		"pt": "res://education/playtown/audio/voice/pt/world/teacher.mp3",
		"es": "res://education/playtown/audio/voice/es/world/teacher.mp3",
		"fr": "res://education/playtown/audio/voice/fr/world/teacher.mp3",
		"de": "res://education/playtown/audio/voice/de/world/teacher.mp3",
	},
	"seller": {
		"en": "res://education/playtown/audio/voice/en/world/seller.mp3",
		"ru": "res://education/playtown/audio/voice/ru/world/seller.mp3",
		"pt": "res://education/playtown/audio/voice/pt/world/seller.mp3",
		"es": "res://education/playtown/audio/voice/es/world/seller.mp3",
		"fr": "res://education/playtown/audio/voice/fr/world/seller.mp3",
		"de": "res://education/playtown/audio/voice/de/world/seller.mp3",
	},
}

var current_locale := DEFAULT_LOCALE
var interface_locale := DEFAULT_LOCALE
var learning_locale := DEFAULT_LOCALE
var has_confirmed_locale := false
var picker_requested := false
var picker_return_scene := CHARACTER_SELECT_SCENE


func _ready() -> void:
	_load_language()


func set_locale(locale: String, persist: bool = true) -> void:
	var normalized := _normalize_locale(locale)
	var changed := current_locale != normalized
	current_locale = normalized
	interface_locale = normalized
	learning_locale = normalized
	TranslationServer.set_locale(interface_locale)
	if persist:
		has_confirmed_locale = true
		_save_language()
	if changed:
		language_changed.emit(current_locale)


func set_interface_locale(locale: String, persist: bool = true) -> void:
	interface_locale = _normalize_locale(locale)
	TranslationServer.set_locale(interface_locale)
	if persist:
		has_confirmed_locale = true
		_save_language()
	language_changed.emit(interface_locale)


func set_learning_locale(locale: String, persist: bool = true) -> void:
	learning_locale = _normalize_locale(locale)
	current_locale = learning_locale
	if persist:
		has_confirmed_locale = true
		_save_language()
	language_changed.emit(learning_locale)


func request_language_picker(return_scene: String) -> void:
	picker_requested = true
	picker_return_scene = return_scene if not return_scene.is_empty() else CHARACTER_SELECT_SCENE


func finish_language_picker() -> String:
	var return_scene := picker_return_scene
	picker_requested = false
	picker_return_scene = CHARACTER_SELECT_SCENE
	return return_scene


func should_skip_language_picker() -> bool:
	return has_confirmed_locale and not picker_requested


func suggested_locale() -> String:
	return current_locale


func language_name(locale: String) -> String:
	var normalized := _normalize_locale(locale)
	return String(LANGUAGE_NAMES.get(normalized, normalized.to_upper()))


func get_ui_text(key: String, locale: String = "") -> String:
	var chosen := _normalize_locale(locale if not locale.is_empty() else interface_locale)
	var entries: Dictionary = UI_TEXT.get(key, {})
	return String(entries.get(chosen, entries.get(DEFAULT_LOCALE, key)))


func get_title_texture_path(key: String, locale: String = "") -> String:
	var chosen := _normalize_locale(locale if not locale.is_empty() else interface_locale)
	var entries: Dictionary = TITLE_TEXTURES.get(key, {})
	return String(entries.get(chosen, entries.get(DEFAULT_LOCALE, "")))


func get_ui_voice(key: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else interface_locale)
	var entries: Dictionary = UI_VOICES.get(key, {})
	var path := String(entries.get(chosen, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_game_voice(key: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else interface_locale)
	var entries: Dictionary = GAME_VOICES.get(key, {})
	var path := String(entries.get(chosen, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_shape_voice(shape: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var entries: Dictionary = SHAPE_VOICES.get(shape, {})
	var path := String(entries.get(chosen, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_shape_name(shape: String, locale: String = "") -> String:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var entries: Dictionary = SHAPE_NAMES.get(shape, {})
	return String(entries.get(chosen, entries.get(DEFAULT_LOCALE, shape.to_upper())))


func get_animal_voice(animal_key: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var path := "res://education/playtown/audio/voice/%s/animals/%s.mp3" % [chosen, animal_key]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_habitat_voice(habitat: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var path := "res://education/playtown/audio/voice/%s/habitats/%s.mp3" % [chosen, habitat]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_clothing_voice(category: String, fallback: AudioStream = null, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var entries: Dictionary = CLOTHING_VOICES.get(category, {})
	var path := String(entries.get(chosen, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return fallback
	return load(path) as AudioStream


func get_world_voice(character: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else interface_locale)
	var entries: Dictionary = WORLD_VOICES.get(character, {})
	var path := String(entries.get(chosen, entries.get(DEFAULT_LOCALE, "")))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_alphabet() -> Array[String]:
	if learning_locale == "ru":
		return RU_ALPHABET.duplicate()
	if learning_locale == "es":
		return ES_ALPHABET.duplicate()
	var latin: Array[String] = []
	for code in range(65, 91):
		latin.append(String.chr(code))
	return latin


func get_letter_voice(character: String) -> AudioStream:
	var alphabet := get_alphabet()
	var spoken_character := character.to_upper()
	if learning_locale == "pt":
		spoken_character = String(PT_LETTER_BASES.get(spoken_character, spoken_character))
	elif learning_locale == "es":
		spoken_character = String(ES_LETTER_BASES.get(spoken_character, spoken_character))
	elif learning_locale == "fr":
		spoken_character = String(FR_LETTER_BASES.get(spoken_character, spoken_character))
	elif learning_locale == "de":
		spoken_character = String(DE_LETTER_BASES.get(spoken_character, spoken_character))
	var index := alphabet.find(spoken_character)
	if index < 0:
		return null
	var extension := "ogg" if learning_locale == "ru" else "mp3"
	var path := "res://education/playtown/audio/voice/%s/alphabet/alpha_%03d.%s" % [learning_locale, index + 1, extension]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_number_voice(number: int, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	if chosen in ["ru", "en", "pt", "es", "fr", "de"]:
		var localized_path := "res://education/playtown/audio/voice/%s/numbers/number_%02d.mp3" % [chosen, clampi(number, 0, 10)]
		if ResourceLoader.exists(localized_path):
			return load(localized_path) as AudioStream
	var english_path := "res://education/playtown/audio/sfx/numbers/en_num_%02d.ogg" % clampi(number, 0, 10)
	if ResourceLoader.exists(english_path):
		return load(english_path) as AudioStream
	return null


func get_math_voice(operation: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	if chosen not in ["ru", "en", "pt", "es", "fr", "de"] or operation not in ["plus", "minus"]:
		return null
	var path := "res://education/playtown/audio/voice/%s/math/%s.mp3" % [chosen, operation]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func get_trace_action_voice(action_index: int, locale: String = "") -> AudioStream:
	return _get_structured_voice(
		"draw_this",
		"TRACE_ACTION_%03d.mp3" % clampi(action_index, 1, 5),
		locale
	)


func get_color_voice(
	color_index: int,
	feminine: bool = false,
	locale: String = "",
	grammatical_gender: String = ""
) -> AudioStream:
	var gender := grammatical_gender.to_upper()
	if gender not in ["M", "F", "N"]:
		gender = "F" if feminine else "M"
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var stream := _get_structured_voice(
		"colors",
		"COLOR_%s_%03d.mp3" % [gender, clampi(color_index + 1, 1, 7)],
		chosen
	)
	if stream != null:
		return stream
	if feminine and chosen in ["pt", "es", "fr"]:
		stream = _get_structured_voice(
			"colors",
			"COLOR_M_%03d.mp3" % clampi(color_index + 1, 1, 7),
			chosen
		)
		if stream != null:
			return stream
	return _get_structured_voice(
		"colors",
		"COLOR_%03d.mp3" % clampi(color_index + 1, 1, 7),
		chosen
	)


func get_shape_color_voice(color_index: int, shape_key: String, locale: String = "") -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var gender := "F" if shape_key == "star" else "M"
	if chosen == "de":
		if shape_key == "diamond":
			gender = "F"
		elif shape_key in ["square", "triangle", "rectangle"]:
			gender = "N"
		else:
			gender = "M"
	return get_color_voice(color_index, gender == "F", chosen, gender)


func get_profession_voice(profession_index: int, locale: String = "") -> AudioStream:
	return _get_structured_voice(
		"professions",
		"PROF_%03d.mp3" % clampi(profession_index + 1, 1, 8),
		locale
	)


func get_profession_action_voice(locale: String = "") -> AudioStream:
	return _get_structured_voice("professions", "PROF_ACTION_001.mp3", locale)


func get_profession_item_voice(item_index: int, locale: String = "") -> AudioStream:
	var profession_number := clampi(floori(float(item_index) / 4.0) + 1, 1, 8)
	var item_number := posmod(item_index, 4) + 1
	return _get_structured_voice(
		"professions",
		"PROF_%03d_ITEM_%02d.mp3" % [profession_number, item_number],
		locale
	)


func get_pizza_voice(key: String, locale: String = "") -> AudioStream:
	var stream := _get_structured_voice("pizza_fraction", "%s.mp3" % key, locale)
	if stream != null:
		return stream
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	if chosen not in ["en", "pt", "es", "fr", "de"]:
		return null
	if key == "PIZZA_NUM_001" and chosen in ["es", "de"]:
		return _get_structured_voice("pizza_fraction", "FRACTION_NUM_001.mp3", chosen)
	if key == "PIZZA_PIECES_003":
		return _get_structured_voice("pizza_fraction", "PIZZA_PIECES_002.mp3", chosen)
	if key.begins_with("FRACTION_DEN_P_") and chosen in ["fr", "de"]:
		return _get_structured_voice(
			"pizza_fraction",
			"FRACTION_DEN_S_%s.mp3" % key.get_slice("_", 3),
			chosen
		)
	if key.begins_with("PIZZA_TOTAL_") or key.begins_with("FRACTION_NUM_"):
		var number_text := key.get_slice("_", 2)
		if number_text.is_valid_int():
			return get_number_voice(int(number_text), chosen)
	return null


func _get_structured_voice(folder: String, file_name: String, locale: String) -> AudioStream:
	var chosen := _normalize_locale(locale if not locale.is_empty() else learning_locale)
	var path := "res://education/playtown/audio/voice/%s/%s/%s" % [chosen, folder, file_name]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _load_language() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		interface_locale = _normalize_locale(String(cfg.get_value("language", "interface", DEFAULT_LOCALE)))
		learning_locale = _normalize_locale(String(cfg.get_value("language", "learning", interface_locale)))
		has_confirmed_locale = bool(cfg.get_value("language", "confirmed", false))
	else:
		interface_locale = _device_locale()
		learning_locale = interface_locale
	current_locale = learning_locale
	TranslationServer.set_locale(interface_locale)


func _save_language() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("language", "interface", interface_locale)
	cfg.set_value("language", "learning", learning_locale)
	cfg.set_value("language", "confirmed", has_confirmed_locale)
	cfg.save(SAVE_PATH)


func _device_locale() -> String:
	var locale := TranslationServer.get_locale().replace("-", "_").split("_")[0]
	return _normalize_locale(locale)


func _normalize_locale(locale: String) -> String:
	var normalized := locale.strip_edges().to_lower().replace("-", "_").split("_")[0]
	if not SUPPORTED_LOCALES.has(normalized):
		return DEFAULT_LOCALE
	return normalized

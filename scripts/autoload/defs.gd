extends Node
## Все игровые данные: здания, защита, пакости, клиенты, тексты.

const VERSION := "1.1.0"
const DEFAULT_PORT := 7777

const TEAM_NAMES := ["Золотой Лотос", "Неоновый Койот"]
const TEAM_SHORT := ["Лотос", "Койот"]
const TEAM_COLORS := [Color(1.0, 0.72, 0.16), Color(0.16, 0.9, 1.0)]
const TEAM_ACCENT := [Color(1.0, 0.22, 0.18), Color(1.0, 0.24, 0.72)]

const START_MONEY := 1500
const MAX_LEVEL := 10
# Стоимость перехода на уровень N (индекс = N).
const LEVEL_COST := [0, 0, 1200, 3000, 6000, 9000, 13000, 18000, 24000, 31000, 40000]

const ROLES := {
	"boss": {"name": "Владелец", "desc": "Делает всё сам. Без бонусов."},
	"director": {"name": "Директор", "desc": "Стройка, найм и улучшения на 10% дешевле."},
	"saboteur": {"name": "Пакостник", "desc": "Пакости на 15% дешевле, ловят на 7% реже."},
}

# ---------------------------------------------------------------------------
# Здания. attract — привлекательность фасада, cap — вместимость, spend — множитель трат,
# comfort, music, smell — параметры, prefs — бонус привлекательности для типов клиентов.
const FACILITIES := [
	{"id": "slots", "name": "Игровые автоматы", "lvl": 1, "cost": 300, "icon": "777", "col": Color(1, 0.3, 0.3),
		"attract": 4, "cap": 6, "spend": 0.25, "desc": "Мигают, звенят и бережно избавляют от пенсии."},
	{"id": "bar", "name": "Бар «Последняя рюмка»", "lvl": 1, "cost": 450, "icon": "BAR", "col": Color(0.9, 0.5, 0.15),
		"attract": 3, "cap": 4, "spend": 0.2, "prefs": {"drunk": 18}, "desc": "Пьяные клиенты летят сюда как мотыльки на свет."},
	{"id": "toilet", "name": "Туалет", "lvl": 1, "cost": 250, "icon": "WC", "col": Color(0.4, 0.75, 1),
		"comfort": 12, "prefs": {"family": 8}, "desc": "Роскошь, которой у соседа нет. Пока что."},
	{"id": "sign", "name": "Неоновая вывеска", "lvl": 2, "cost": 900, "icon": "NEO", "col": Color(1, 0.25, 0.8),
		"attract": 10, "desc": "Видна из космоса. И из окон соседей, что особенно приятно."},
	{"id": "music", "name": "Музыкальная система", "lvl": 2, "cost": 800, "icon": "♪", "col": Color(0.6, 0.4, 1),
		"music": 9, "attract": 2, "desc": "Басы, от которых у соседей трескается штукатурка."},
	{"id": "aroma", "name": "Аромат «Запах денег»", "lvl": 3, "cost": 1500, "icon": "$$$", "col": Color(0.4, 1, 0.5),
		"smell": 10, "desc": "Пахнет купюрами и лёгкой надеждой."},
	{"id": "fountain", "name": "Фонтан желаний", "lvl": 3, "cost": 1800, "icon": "≈", "col": Color(0.3, 0.8, 1),
		"attract": 8, "prefs": {"family": 6}, "passive": 2.0, "desc": "Клиенты кидают монеты. Мы их вылавливаем."},
	{"id": "slots2", "name": "Золотые автоматы", "lvl": 3, "cost": 2200, "icon": "$7$", "col": Color(1, 0.8, 0.2),
		"attract": 5, "cap": 8, "spend": 0.35, "desc": "Тот же автомат, но золотой. Проигрывать в нём престижнее."},
	{"id": "restaurant", "name": "Ресторан «Последний ужин»", "lvl": 4, "cost": 5000, "icon": "ЕДА", "col": Color(1, 0.55, 0.3),
		"attract": 6, "cap": 6, "spend": 0.3, "comfort": 10, "prefs": {"family": 16, "vip": 4}, "desc": "Сытый клиент проигрывает дольше."},
	{"id": "hotel", "name": "Отель «Не уйдёшь»", "lvl": 5, "cost": 9000, "icon": "H", "col": Color(0.9, 0.9, 1),
		"attract": 8, "cap": 10, "stay": 0.4, "passive": 8.0, "prefs": {"vip": 10, "family": 6}, "desc": "Номера с видом на казино. Выход — через казино."},
	{"id": "vip", "name": "VIP-зона", "lvl": 6, "cost": 12000, "icon": "VIP", "col": Color(1, 0.85, 0.3),
		"attract": 6, "cap": 4, "spend": 0.6, "prefs": {"vip": 30}, "desc": "Красная дорожка, бархатные канаты, золотые унитазы."},
	{"id": "dealers", "name": "Живые крупье", "lvl": 7, "cost": 17000, "icon": "♠", "col": Color(0.2, 0.85, 0.4),
		"attract": 6, "cap": 8, "spend": 0.8, "prefs": {"vip": 10}, "desc": "Улыбаются, тасуют, никогда не проигрывают."},
	{"id": "show", "name": "Шоу «Танцующие должники»", "lvl": 8, "cost": 23000, "icon": "★", "col": Color(1, 0.4, 0.9),
		"attract": 18, "spend": 0.3, "music": 6, "desc": "Шоу на крыше с прожекторами. Танцуют те, кто нам должен."},
	{"id": "lift", "name": "Стеклянный лифт в пентхаус", "lvl": 9, "cost": 30000, "icon": "▲", "col": Color(0.6, 1, 1),
		"attract": 8, "cap": 6, "spend": 0.5, "prefs": {"vip": 20}, "desc": "Чем выше этаж, тем крупнее ставки."},
	{"id": "fireworks", "name": "Салют каждую минуту", "lvl": 9, "cost": 26000, "icon": "✸", "col": Color(1, 0.6, 0.2),
		"attract": 15, "desc": "Сосед не спит. Сосед злится. Сосед проигрывает."},
	{"id": "dome", "name": "Золотой купол", "lvl": 10, "cost": 45000, "icon": "◓", "col": Color(1, 0.8, 0.1),
		"attract": 25, "spend": 0.5, "regen": 0.05, "desc": "Венец империи. Отражает солнце прямо соседям в окна."},
]

# Защита: постоянное содержание (upkeep) в минуту.
const DEFENSES := [
	{"id": "cameras", "name": "Камеры наблюдения", "lvl": 2, "cost": 1200, "upkeep": 60, "icon": "CAM", "col": Color(0.7, 0.7, 0.8),
		"catch": 0.15, "desc": "+15% шанс поймать пакостника. Ловят шулеров."},
	{"id": "cleaner", "name": "Чистильщик", "lvl": 3, "cost": 1500, "upkeep": 120, "icon": "ШВБ", "col": Color(0.4, 0.9, 0.6),
		"desc": "Тараканы, вонь и потопы проходят вдвое быстрее."},
	{"id": "guards", "name": "Охрана", "lvl": 4, "cost": 4000, "upkeep": 250, "icon": "ОХР", "col": Color(0.3, 0.3, 0.35),
		"catch": 0.12, "desc": "+12% к поимке. Скручивают дебоширов и шулеров. Слабее фальшивки."},
	{"id": "lawyer", "name": "Юрист", "lvl": 5, "cost": 7000, "upkeep": 400, "icon": "§", "col": Color(0.5, 0.6, 1),
		"desc": "Потери репутации −40%, штрафы −50%. Отбивается от прессы."},
	{"id": "pr", "name": "Контр-пропаганда", "lvl": 6, "cost": 9000, "upkeep": 450, "icon": "PR", "col": Color(1, 0.5, 0.5),
		"desc": "Слухи и новости бьют вдвое слабее. Репутация медленно растёт."},
	{"id": "detective", "name": "Детектив", "lvl": 8, "cost": 18000, "upkeep": 700, "icon": "?!", "col": Color(0.8, 0.65, 0.4),
		"catch": 0.25, "desc": "+25% к поимке. Даже без поимки находит улики против соседа."},
]

# Пакости. tier: 0 лёгкие, 1 средние, 2 тяжёлые, 3 «Тотальные» (10 ур.).
# self=true — бафф себе, а не удар по соседу.
const SABOTAGES := [
	{"id": "roaches", "name": "Тараканы", "tier": 0, "lvl": 1, "cost": 400, "cd": 40, "dur": 60, "catch": 0.12, "icon": "ЖУК",
		"desc": "Подкинуть коробку тараканов. Семьи в ужасе, репутация тает."},
	{"id": "stink", "name": "Вонючка", "tier": 0, "lvl": 1, "cost": 350, "cd": 35, "dur": 45, "catch": 0.10, "icon": "ФУ",
		"desc": "Тухлая рыба в вентиляции. Классика."},
	{"id": "music_break", "name": "Порча музыки", "tier": 0, "lvl": 2, "cost": 600, "cd": 45, "dur": 60, "catch": 0.12, "icon": "♪✕",
		"desc": "Заменить плейлист на шансон задом наперёд."},
	{"id": "rumor", "name": "Фейковые слухи", "tier": 0, "lvl": 2, "cost": 700, "cd": 50, "dur": 90, "catch": 0.08, "icon": "БЛА",
		"desc": "«Говорят, там автоматы на батарейках и крупье — бывший карманник»."},
	{"id": "taxi", "name": "Подкуп таксистов", "tier": 0, "lvl": 3, "cost": 1200, "cd": 60, "dur": 75, "catch": 0.15, "icon": "ТАКСИ",
		"desc": "Все такси везут клиентов к тебе. Даже тех, кто ехал к соседу."},
	{"id": "brawlers", "name": "Скандалисты", "tier": 1, "lvl": 4, "cost": 3000, "cd": 70, "dur": 0, "catch": 0.18, "icon": "!!!",
		"desc": "Трое крикливых мужиков идут устраивать сцену. Охрана может их скрутить."},
	{"id": "plumbing", "name": "Поломка туалетов и лифта", "tier": 1, "lvl": 5, "cost": 4500, "cd": 80, "dur": 70, "catch": 0.2, "icon": "ПОТОП",
		"desc": "Фонтан из унитаза. Лифт застрял с бабушкой внутри."},
	{"id": "fakemoney", "name": "Фальшивые деньги", "tier": 1, "lvl": 6, "cost": 6000, "cd": 90, "dur": 60, "catch": 0.22, "icon": "$✕",
		"desc": "Кассы соседа забиты фантиками. Доход −40% (с охраной −20%)."},
	{"id": "dealer_bribe", "name": "Подкуп крупье", "tier": 2, "lvl": 7, "cost": 12000, "cd": 120, "dur": 60, "catch": 0.25, "icon": "♠$",
		"desc": "Крупье соседа «случайно» проигрывает. Сосед теряет 8% денег, доход падает."},
	{"id": "news", "name": "Скандал в новостях", "tier": 2, "lvl": 8, "cost": 16000, "cd": 120, "dur": 60, "catch": 0.25, "icon": "ТВ",
		"desc": "Съёмочная группа у входа. Репутация −15 и дурная слава."},
	{"id": "exodus", "name": "Массовый уход клиентов", "tier": 2, "lvl": 9, "cost": 20000, "cd": 150, "dur": 30, "catch": 0.3, "icon": "ВОН",
		"desc": "Ложная пожарная тревога. Все клиенты выбегают, половина — к тебе."},
	{"id": "black_monday", "name": "Чёрный понедельник", "tier": 3, "lvl": 10, "cost": 40000, "cd": 240, "dur": 120, "catch": 0.3, "icon": "ПН",
		"desc": "Над соседом грозовая туча, доход −70%, репутация −10. Даже если сегодня пятница."},
	{"id": "grand_raffle", "name": "Большой розыгрыш", "tier": 3, "lvl": 10, "cost": 30000, "cd": 180, "dur": 60, "catch": 0.0, "icon": "WIN", "self": true,
		"desc": "Розыгрыш квартиры (в ипотеку). Вдвое больше людей на улице, все идут к тебе."},
	{"id": "sign_war", "name": "Война вывесок", "tier": 3, "lvl": 10, "cost": 25000, "cd": 180, "dur": 90, "catch": 0.2, "icon": "VS",
		"desc": "Твоя вывеска становится гигантской, вывеска соседа гаснет."},
	{"id": "road_op", "name": "Операция «Дорога»", "tier": 3, "lvl": 10, "cost": 35000, "cd": 200, "dur": 75, "catch": 0.25, "icon": "ДОР",
		"desc": "Срочный «ремонт» прямо перед входом соседа. Пешком к нему не пройти."},
]

const TIER_NAMES := ["Лёгкие пакости", "Средние пакости", "Тяжёлые пакости", "Тотальные саботажи"]
const TIER_COLORS := [Color(0.55, 0.9, 0.4), Color(1, 0.75, 0.25), Color(1, 0.35, 0.3), Color(0.85, 0.3, 1)]

# Активные способности (свои кнопки, с перезарядкой).
const ABILITIES := [
	{"id": "cleanup", "name": "Экстренная уборка", "lvl": 1, "base": 250, "per_lvl": 150, "cd": 60, "icon": "ЧИСТ",
		"desc": "Убирает тараканов, вонь, потоп и чинит музыку."},
	{"id": "party", "name": "Бесплатные коктейли", "lvl": 2, "base": 500, "per_lvl": 300, "cd": 90, "dur": 45, "icon": "ПАТИ",
		"desc": "+15 к привлекательности на 45 сек. Толпа у входа гарантирована."},
	{"id": "pr_campaign", "name": "PR-кампания", "lvl": 3, "base": 800, "per_lvl": 400, "cd": 120, "icon": "+REP",
		"desc": "Репутация +8, слухи и скандалы в новостях заканчиваются."},
]

# Клиенты.
const CLIENT_TYPES := ["normal", "vip", "drunk", "family", "cheater", "brawler"]
const CLIENTS := {
	"normal": {"name": "Обычный", "w": 50, "spend": 45.0, "stay": 16.0, "speed": 2.1},
	"vip": {"name": "VIP", "w": 5, "spend": 220.0, "stay": 22.0, "speed": 1.9},
	"drunk": {"name": "Пьяный", "w": 14, "spend": 32.0, "stay": 12.0, "speed": 1.35},
	"family": {"name": "Семья", "w": 12, "spend": 80.0, "stay": 20.0, "speed": 1.6},
	"cheater": {"name": "Шулер", "w": 8, "spend": -45.0, "stay": 14.0, "speed": 2.5},
	"brawler": {"name": "Скандалист", "w": 0, "spend": 0.0, "stay": 0.0, "speed": 2.6},
}

# ---------------------------------------------------------------------------
# Реплики — чёрный юмор.
const LINES := {
	"enter": ["Ставлю квартиру!", "Сегодня мой день!", "Только посмотреть...", "Жена думает, я в библиотеке",
		"Чувствую удачу!", "Последний раз, честно", "Кредит одобрен!", "Мама, я богач!"],
	"leave_happy": ["Выиграл! Почти...", "Приду завтра!", "Какой сервис!", "Проиграл ипотеку. Кайф!", "Лучшее казино района!"],
	"leave_sad": ["Больше ни ногой", "Где мои штаны?", "Обобрали до нитки", "У соседей лучше"],
	"queue": ["Очередь как в поликлинике!", "Я тут с утра стою", "Ну и сервис...", "Пойду к соседям"],
	"roaches": ["Фу, там тараканы!", "Таракан украл мои фишки!", "Там жуки размером с кошку"],
	"stink": ["Чем это так воняет?", "Глаза слезятся!", "Кто-то сдох в вентиляции?"],
	"music_break": ["Что за шансон?!", "У меня уши кровоточат", "Это музыка или пытка?"],
	"rumor": ["Говорят, там автоматы на батарейках", "Говорят, там травят!", "Слышал, крупье — карманник"],
	"news": ["Видел по ТВ, там жуть", "Это то самое казино из новостей?"],
	"plumbing": ["Там потоп!", "Туалет фонтанирует!", "Лифт застрял с бабушкой!"],
	"road_op": ["Ремонт?! Опять?!", "Как туда пройти вообще?"],
	"black_monday": ["Над ними туча... плохой знак", "Там как на похоронах"],
	"exodus": ["ПОЖАР!!!", "Спасайся кто может!", "Мои фишки!!!"],
	"brawl": ["Да я тебя!..", "Где директор?!", "Верните мои деньги!", "Вы все жулики!"],
	"brawl_caught": ["Пустите! Я только спросить!", "Ай, ухо!", "Я буду жаловаться!"],
	"cheater_caught": ["Это не мои карты!", "Я просто фокусник!", "Меня подставили!"],
	"drunk": ["Ик!", "Где я?", "Я вас всех люблю!", "Ещё по одной!", "Мне в другое казино... или в это"],
	"vip": ["Где тут VIP?", "Шампанского!", "Мелочь оставьте себе"],
	"taxi": ["Таксист сказал, тут лучше", "Водитель настоял"],
	"raffle": ["Розыгрыш квартиры?!", "Хочу квартиру!", "Бесплатно? Беру!"],
	"party": ["Бесплатные коктейли?!", "Тусим!"],
	"lured": ["Флаер? Ну ладно, загляну", "Бесплатный коктейль? Иду!", "Уговорили, черти", "А там правда лучше?", "Ладно, последний раз..."],
	"punched": ["Ай! За что?!", "Полиция!!!", "Я на вас в суд подам!", "Больно же!", "Психи какие-то"],
	"car_hit": ["Сбили! Человека сбили!", "Он сам выскочил!", "Смотри куда прёшь!", "Ой-ой, живой?"],
}

var fac_by_id := {}
var def_by_id := {}
var sab_by_id := {}
var abil_by_id := {}

# Настройки игрока (user://settings.cfg)
signal settings_changed
var quality := 2
var fullscreen := false
var volume := 0.8
var last_ip := ""
var player_name := ""


func _ready() -> void:
	for f in FACILITIES:
		fac_by_id[f.id] = f
	for d in DEFENSES:
		def_by_id[d.id] = d
	for s in SABOTAGES:
		sab_by_id[s.id] = s
	for a in ABILITIES:
		abil_by_id[a.id] = a
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		quality = int(cfg.get_value("video", "quality", 2))
		fullscreen = bool(cfg.get_value("video", "fullscreen", false))
		volume = float(cfg.get_value("audio", "volume", 0.8))
		last_ip = String(cfg.get_value("net", "last_ip", ""))
		player_name = String(cfg.get_value("net", "name", ""))
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("net", "last_ip", last_ip)
	cfg.set_value("net", "name", player_name)
	cfg.save("user://settings.cfg")


func apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	settings_changed.emit()


func line(key: String) -> String:
	var arr: Array = LINES.get(key, [])
	return "" if arr.is_empty() else arr[randi() % arr.size()]


static func money(v: float) -> String:
	var n := int(round(abs(v)))
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 and n != 0 else "") + "$" + s + out


static func time_str(sec: float) -> String:
	var s := int(max(sec, 0.0))
	return "%d:%02d" % [s / 60, s % 60]

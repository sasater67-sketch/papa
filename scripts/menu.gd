extends Node
## Главное меню: фоновое демо ИИ против ИИ, одиночная игра, хост/подключение, лобби, настройки.

const T := preload("res://scripts/ui/ui_theme.gd")
const World := preload("res://scripts/world/world.gd")
const CamRig := preload("res://scripts/world/cam_rig.gd")

var cam: Node3D
var _ui: Control
var _right: PanelContainer
var _content: VBoxContainer
var _status: Label
var _name: LineEdit
var _section := ""
var _solo := {"duration": 20, "ai": 1}


func _ready() -> void:
	get_tree().paused = false
	Game.start_demo()
	Sfx.music("menu", -14.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(World.new())
	cam = CamRig.new()
	cam.auto_orbit = true
	cam.input_enabled = false
	add_child(cam)
	cam.target = Vector3(0, 4, 0)
	cam.dist = 56.0
	cam.elev = 0.36
	cam.yaw = 0.9
	cam.snap()
	_build_ui()
	Net.lobby_changed.connect(_on_lobby_changed)
	Net.connected_ok.connect(func(): _set_status("Подключено! Ждём данные лобби...", T.GOOD))
	Net.connection_failed.connect(func(r): _on_net_error(r))
	Net.disconnected.connect(func(r): _on_net_error(r))
	if Net.has_meta("menu_message"):
		_set_status(String(Net.get_meta("menu_message")), T.BAD)
		Net.remove_meta("menu_message")
	if "--dev" in OS.get_cmdline_user_args() and not get_tree().root.has_node("Dev"):
		var dev: Node = load("res://scripts/dev.gd").new()
		dev.name = "Dev"
		get_tree().root.add_child.call_deferred(dev)


# =============================================================================
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.theme = T.make()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	# Затемнение слева для читаемости
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.0, 0.05, 0.92))
	g.set_color(1, Color(0.02, 0.0, 0.05, 0.0))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	grad.texture = gt
	grad.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	grad.offset_right = 1250
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(grad)
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 56
	root.offset_top = 40
	root.offset_bottom = -40
	root.add_theme_constant_override("separation", 28)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(400, 0)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	var t1 := T.shadowed(T.lbl("CASINO WARS", 74, T.GOLD, true), 14, Color(0.6, 0.1, 0.25, 0.9))
	left.add_child(t1)
	var t2 := T.shadowed(T.lbl("ACROSS THE ROAD", 30, Defs.TEAM_COLORS[1], true), 8, Color(0.0, 0.1, 0.3, 0.9))
	left.add_child(t2)
	var t3 := T.lbl("Два казино. Одна дорога. Никакой совести.", 18, T.DIM)
	left.add_child(t3)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 24)
	left.add_child(sp)
	var lp := T.panel()
	left.add_child(lp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	lp.add_child(lv)
	lv.add_child(T.lbl("Ваше имя", 14, T.DIM))
	_name = LineEdit.new()
	_name.text = Net.my_name
	_name.max_length = 20
	_name.text_changed.connect(func(s):
		Net.my_name = s.strip_edges() if s.strip_edges() != "" else "Игрок"
		Defs.player_name = Net.my_name
		Defs.save_settings())
	lv.add_child(_name)
	_menu_btn(lv, "Играть против ИИ", _show_solo)
	_menu_btn(lv, "Создать игру (хост)", _show_host)
	_menu_btn(lv, "Подключиться к другу", _show_join)
	_menu_btn(lv, "Настройки", _show_settings)
	_menu_btn(lv, "Как играть", _show_help)
	_menu_btn(lv, "Выход", func(): get_tree().quit())
	_status = T.lbl("", 15, T.GOLD)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(380, 0)
	left.add_child(_status)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(fill)
	left.add_child(T.lbl("v%s • Godot %s • на фоне ИИ воюет сам с собой" % [Defs.VERSION, Engine.get_version_info().string], 12, Color(0.5, 0.46, 0.58)))
	_right = T.panel(T.BG, Color(T.GOLD.r, T.GOLD.g, T.GOLD.b, 0.45), 2, 20)
	_right.custom_minimum_size = Vector2(640, 0)
	_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_right.visible = false
	root.add_child(_right)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(600, 560)
	_right.add_child(sc)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	sc.add_child(_content)


func _menu_btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override("font_size", 20)
	b.mouse_entered.connect(func(): Sfx.play("hover", -14.0))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	parent.add_child(b)
	return b


func _set_status(text: String, c := T.GOLD) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", c)


func _open(section: String, title: String) -> void:
	_section = section
	_right.visible = true
	for c in _content.get_children():
		c.free()
	var t := T.shadowed(T.lbl(title, 30, T.GOLD, true))
	_content.add_child(t)


func _row(label: String, ctrl: Control) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := T.lbl(label, 16, T.DIM)
	l.custom_minimum_size = Vector2(210, 0)
	h.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(ctrl)
	_content.add_child(h)


func _option(items: Array, selected: int, cb: Callable) -> OptionButton:
	var o := OptionButton.new()
	for i in items:
		o.add_item(i)
	o.selected = selected
	o.item_selected.connect(cb)
	return o


func _text(t: String, size := 15, c := T.TEXT) -> Label:
	var l := T.lbl(t, size, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(l)
	return l


func _big_btn(text: String, cb: Callable, color := T.GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", color)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	_content.add_child(b)
	return b


const DURATIONS := [10, 15, 20, 30]
const DIFFS := ["Лёгкий", "Нормальный", "Жёсткий"]


# =============================================================================
func _show_solo() -> void:
	_open("solo", "ИГРА ПРОТИВ ИИ")
	_text("Вы — «Золотой Лотос». Напротив — «Неоновый Койот» под управлением злобного ИИ, который тоже умеет пакостить.", 16, T.DIM)
	_row("Сложность ИИ", _option(DIFFS, _solo.ai, func(i): _solo.ai = i))
	_row("Длительность", _option(DURATIONS.map(func(d): return "%d минут" % d), DURATIONS.find(_solo.duration), func(i): _solo.duration = DURATIONS[i]))
	_big_btn("В БОЙ!", func(): Net.start_solo(_solo))


func _show_host() -> void:
	if Net.online:
		_show_lobby()
		return
	_open("host", "СОЗДАТЬ ИГРУ")
	_text("Вы станете хостом. Друзья подключатся к вам по IP через Radmin VPN (или любую локальную сеть).", 16, T.DIM)
	_text("1. Запустите Radmin VPN, создайте или войдите в общую сеть с друзьями.\n2. Нажмите «Создать», затем сообщите друзьям ваш IP из Radmin (26.x.x.x).\n3. Если Windows спросит про брандмауэр — разрешите доступ для Godot / игры.", 15)
	var port := LineEdit.new()
	port.text = str(Defs.DEFAULT_PORT)
	_row("Порт", port)
	_big_btn("СОЗДАТЬ", func():
		var err := Net.host(int(port.text) if port.text.is_valid_int() else Defs.DEFAULT_PORT)
		if err != "":
			_set_status(err, T.BAD)
		else:
			_set_status("Сервер запущен. Ждём друзей!", T.GOOD)
			_show_lobby())


func _show_join() -> void:
	if Net.online:
		_show_lobby()
		return
	_open("join", "ПОДКЛЮЧИТЬСЯ")
	_text("Введите IP хоста из Radmin VPN (вида 26.12.34.56). Хост должен сначала нажать «Создать игру».", 16, T.DIM)
	var ip := LineEdit.new()
	ip.placeholder_text = "26.x.x.x"
	ip.text = Defs.last_ip
	_row("IP хоста", ip)
	var port := LineEdit.new()
	port.text = str(Defs.DEFAULT_PORT)
	_row("Порт", port)
	_big_btn("ПОДКЛЮЧИТЬСЯ", func():
		Defs.last_ip = ip.text.strip_edges()
		Defs.save_settings()
		var err := Net.join(ip.text, int(port.text) if port.text.is_valid_int() else Defs.DEFAULT_PORT)
		if err != "":
			_set_status(err, T.BAD)
		else:
			_set_status("Подключаемся к %s..." % ip.text.strip_edges())
			_show_lobby())


func _show_lobby() -> void:
	_open("lobby", "ЛОББИ")
	var host := Net.is_host()
	var s := Net.settings
	if host:
		_text("Сообщите друзьям ваш IP и порт %d:" % Defs.DEFAULT_PORT, 15, T.DIM)
		var ips := Net.local_addresses()
		if ips.is_empty():
			_text("Не удалось определить IP. Посмотрите его в окне Radmin VPN.", 15, T.BAD)
		for a in ips:
			var h := HBoxContainer.new()
			var l := T.lbl(a + ("   ← Radmin VPN" if a.begins_with("26.") else ""), 20, T.GOLD if a.begins_with("26.") else T.TEXT, true)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			var cb := Button.new()
			cb.text = "Копировать"
			var addr: String = a
			cb.pressed.connect(func():
				DisplayServer.clipboard_set(addr)
				_set_status("IP %s скопирован" % addr, T.GOOD))
			h.add_child(cb)
			_content.add_child(h)
	elif Net.players.is_empty():
		_text("Подключение... Если долго ничего не происходит — проверьте IP и что хост создал игру.", 16, T.DIM)
		_big_btn("Отмена", _leave, T.BAD)
		return
	var modes := ["1 на 1", "2 на 2"]
	var mode_i := 1 if s.mode == "2v2" else 0
	if host:
		_row("Режим", _option(modes, mode_i, func(i): Net.set_setting("mode", "2v2" if i == 1 else "1v1")))
		_row("Длительность", _option(DURATIONS.map(func(d): return "%d минут" % d), maxi(0, DURATIONS.find(int(s.duration))), func(i): Net.set_setting("duration", DURATIONS[i])))
		_row("Сложность ИИ (для пустых мест)", _option(DIFFS, int(s.ai), func(i): Net.set_setting("ai", i)))
		if s.mode == "2v2":
			var rc := CheckBox.new()
			rc.text = "Делить роли (Директор / Пакостник)"
			rc.button_pressed = bool(s.roles)
			rc.toggled.connect(func(on): Net.set_setting("roles", on))
			_content.add_child(rc)
	else:
		_text("Режим: %s • %d минут • ИИ: %s%s" % [modes[mode_i], int(s.duration), DIFFS[int(s.ai)], " • роли включены" if s.mode == "2v2" and s.roles else ""], 16)
	var teams := HBoxContainer.new()
	teams.add_theme_constant_override("separation", 12)
	_content.add_child(teams)
	for t in 2:
		var p := T.panel(Color(0.05, 0.03, 0.08, 0.95), Defs.TEAM_COLORS[t], 2, 12)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teams.add_child(p)
		var v := VBoxContainer.new()
		p.add_child(v)
		v.add_child(T.lbl(Defs.TEAM_NAMES[t], 20, Defs.TEAM_COLORS[t], true))
		var count := 0
		for id in Net.players:
			var pl: Dictionary = Net.players[id]
			if int(pl.team) != t:
				continue
			count += 1
			var txt := String(pl.name)
			if pl.role != "boss":
				txt += " — " + Defs.ROLES[pl.role].name
			if id == Net.my_id():
				txt += " (вы)"
			if id == 1:
				txt += " [хост]"
			v.add_child(T.lbl(txt, 16, T.TEXT))
		for i in Net.per_team() - count:
			v.add_child(T.lbl("свободно — займёт ИИ", 15, Color(0.5, 0.46, 0.58)))
		if int(Net.me().get("team", -1)) != t:
			var jb := Button.new()
			jb.text = "Играть здесь"
			var tt := t
			jb.pressed.connect(func(): Net.request_team(tt))
			v.add_child(jb)
	if s.mode == "2v2" and s.roles:
		var my_role := Net.my_role()
		var roles := ["director", "saboteur"]
		_row("Моя роль", _option([Defs.ROLES.director.name + " — " + Defs.ROLES.director.desc, Defs.ROLES.saboteur.name + " — " + Defs.ROLES.saboteur.desc],
			maxi(0, roles.find(my_role)), func(i): Net.request_role(roles[i])))
	if host:
		_big_btn("НАЧАТЬ МАТЧ", func(): Net.start_match())
	else:
		_text("Ждём, когда хост начнёт матч...", 16, T.GOLD)
	_big_btn("Покинуть лобби", _leave, T.BAD)


func _leave() -> void:
	Net.close()
	_set_status("Вы вышли из лобби.")
	_right.visible = false
	_section = ""


func _on_lobby_changed() -> void:
	if _section == "lobby" or (Net.online and _section in ["join", "host"]):
		_show_lobby()


func _on_net_error(reason: String) -> void:
	_set_status(reason, T.BAD)
	if _section == "lobby":
		_right.visible = false
		_section = ""


func _show_settings() -> void:
	_open("settings", "НАСТРОЙКИ")
	_row("Качество графики", _option(["Низкое (слабый ПК)", "Среднее", "Высокое"], Defs.quality, func(i):
		Defs.quality = i
		Defs.save_settings()
		Defs.apply_settings()))
	var vol := HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.value = Defs.volume
	vol.value_changed.connect(func(x):
		Defs.volume = x
		Defs.save_settings()
		Defs.apply_settings())
	_row("Громкость", vol)
	var fs := CheckBox.new()
	fs.text = "Полный экран"
	fs.button_pressed = Defs.fullscreen
	fs.toggled.connect(func(on):
		Defs.fullscreen = on
		Defs.save_settings()
		Defs.apply_settings())
	_content.add_child(fs)
	_text("Высокое качество включает отражения на мокром асфальте и объёмный туман. Если игра тормозит — выберите «Среднее» или «Низкое».", 14, T.DIM)


func _show_help() -> void:
	_open("help", "КАК ИГРАТЬ")
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.text = preload("res://scripts/ui/hud.gd").HELP_TEXT + """

[color=#ffc847][b]Сетевая игра через Radmin VPN:[/b][/color]
1. Все запускают Radmin VPN и заходят в одну сеть.
2. Хост: «Создать игру» → сообщает свой IP 26.x.x.x.
3. Остальные: «Подключиться к другу» → вводят IP хоста.
4. В лобби выбираете команды и режим 1 на 1 или 2 на 2. Пустые места займёт ИИ.
Порт по умолчанию 7777 (UDP). Если не подключается — разрешите игру в брандмауэре Windows у хоста."""
	_content.add_child(r)

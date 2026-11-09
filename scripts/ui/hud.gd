extends CanvasLayer
## Интерфейс матча.

const T := preload("res://scripts/ui/ui_theme.gd")

var cam: Node3D
var player: Node3D
var match_node: Node
var my := 0
var en := 1
var role := "boss"
var fp_on := false
var tablet := false
var _side: Control
var _bottom: Control
var _fp_layer: Control
var _prompt: Label
var _hold_bar: ProgressBar
var _ko: ColorRect
var _ko_label: Label
var _flash: ColorRect
var _fp_btn: Button

var _root: Control
var _top := [{}, {}]
var _timer: Label
var _score_l: Label
var _score_bar_l: ColorRect
var _score_bar_r: ColorRect
var _score_bar: Control
var _revenge: Label
var _tabs: TabContainer
var _cards: Array = []
var _upgrade := {}
var _till := {}
var _breakdown: RichTextLabel
var _stats: RichTextLabel
var _sab_risk_note: Label
var _feed: RichTextLabel
var _chat: LineEdit
var _toasts: VBoxContainer
var _pause: Control
var _help: Control
var _end: Control
var _feed_lines: Array = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	my = Net.my_team()
	en = 1 - my
	role = Net.my_role()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = T.make()
	add_child(_root)
	_build_top()
	_build_side()
	_build_feed()
	_build_bottom()
	_toasts = VBoxContainer.new()
	_toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toasts.position = Vector2(-300, 190)
	_toasts.custom_minimum_size = Vector2(600, 0)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(_toasts)
	_build_pause()
	_build_help()
	_build_fp()
	Game.state_updated.connect(_refresh)
	Game.event_logged.connect(_on_event)
	Game.toast.connect(_on_toast)
	Game.match_over.connect(_on_over)
	Game.chat.connect(_on_chat)
	_refresh()
	var who := "Вы играете за «%s»" % Defs.TEAM_NAMES[my]
	if role != "boss":
		who += " — роль: %s" % Defs.ROLES[role].name
	_add_feed("[color=#ffc847]%s. Соседи — «%s» напротив. Развивайтесь и пакостите! [F1] — помощь, [Tab] — выйти на улицу самому.[/color]" % [who, Defs.TEAM_NAMES[en]])
	_on_toast("Добро пожаловать в войну! Вы — «%s»" % Defs.TEAM_NAMES[my], "big")


# =============================================================================
# Верхняя панель
# =============================================================================
func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 10
	bar.offset_right = -10
	bar.offset_top = 8
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	bar.add_child(_team_card(my, true))
	var mid := T.panel(Color(0.04, 0.02, 0.07, 0.85))
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(mid)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mid.add_child(mv)
	_timer = T.shadowed(T.lbl("20:00", 38, T.GOLD, true))
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(_timer)
	_score_bar = Control.new()
	_score_bar.custom_minimum_size = Vector2(0, 14)
	mv.add_child(_score_bar)
	_score_bar_l = ColorRect.new()
	_score_bar_r = ColorRect.new()
	_score_bar_l.color = Defs.TEAM_COLORS[0]
	_score_bar_r.color = Defs.TEAM_COLORS[1]
	_score_bar.add_child(_score_bar_l)
	_score_bar.add_child(_score_bar_r)
	_score_l = T.lbl("", 14, T.DIM)
	_score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(_score_l)
	_revenge = T.lbl("", 14, Color(1, 0.5, 0.3), true)
	_revenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(_revenge)
	bar.add_child(_team_card(en, false))


func _team_card(t: int, mine: bool) -> Control:
	var c: Color = Defs.TEAM_COLORS[t]
	var p := T.panel(Color(0.05, 0.03, 0.08, 0.9), c, 3, 10)
	p.custom_minimum_size = Vector2(500, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var h1 := HBoxContainer.new()
	v.add_child(h1)
	var nm := T.shadowed(T.lbl(("★ " if mine else "") + Defs.TEAM_NAMES[t], 22, c, true))
	h1.add_child(nm)
	var sub := T.lbl("  ВЫ" if mine else "  СОСЕДИ", 13, T.DIM, true)
	h1.add_child(sub)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h1.add_child(sp)
	var lvl := T.lbl("УР. 1", 20, T.GOLD, true)
	h1.add_child(lvl)
	var h2 := HBoxContainer.new()
	h2.add_theme_constant_override("separation", 14)
	v.add_child(h2)
	var money := T.shadowed(T.lbl("$0", 30, Color(1, 0.88, 0.4), true))
	h2.add_child(money)
	var income := T.lbl("", 15, T.GOOD)
	income.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h2.add_child(income)
	var h3 := HBoxContainer.new()
	h3.add_theme_constant_override("separation", 8)
	v.add_child(h3)
	h3.add_child(T.lbl("Репутация", 14, T.DIM))
	var rep := ProgressBar.new()
	rep.max_value = 100
	rep.custom_minimum_size = Vector2(170, 18)
	rep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h3.add_child(rep)
	var crowd := T.lbl("", 14, T.TEXT)
	h3.add_child(crowd)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	v.add_child(chips)
	var players := T.lbl("", 13, T.DIM)
	v.add_child(players)
	_top[t] = {"lvl": lvl, "money": money, "income": income, "rep": rep, "crowd": crowd, "chips": chips, "players": players, "chip_key": ""}
	return p


func _chip(text: String, c: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.box(Color(c.r * 0.25, c.g * 0.25, c.b * 0.25, 0.95), c, 1, 6, 3))
	var l := T.lbl(text, 13, c.lightened(0.3), true)
	p.add_child(l)
	return p


# =============================================================================
# Правая панель с вкладками
# =============================================================================
func _build_side() -> void:
	var side := T.panel(Color(0.045, 0.03, 0.075, 0.9))
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.anchor_top = 0.0
	side.anchor_bottom = 1.0
	side.offset_left = -455
	side.offset_right = -10
	side.offset_top = 200
	side.offset_bottom = -62
	_root.add_child(side)
	_side = side
	_tabs = TabContainer.new()
	_tabs.tab_changed.connect(func(_i): Sfx.play("click", -8.0))
	side.add_child(_tabs)
	_tabs.add_child(_tab_casino())
	_tabs.add_child(_tab_list("Стройка", "build"))
	_tabs.add_child(_tab_list("Защита", "defense"))
	_tabs.add_child(_tab_sabotage())
	if role == "saboteur":
		_tabs.current_tab = 3
	elif role == "director":
		_tabs.current_tab = 1


func _scroll(title: String) -> Array:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	return [sc, v]


func _tab_casino() -> Control:
	var s := _scroll("Казино")
	var v: VBoxContainer = s[1]
	# Карточка улучшения
	var up := T.panel(Color(0.12, 0.07, 0.02, 0.95), T.GOLD, 2, 10)
	v.add_child(up)
	var uv := VBoxContainer.new()
	up.add_child(uv)
	var ut := T.shadowed(T.lbl("Уровень 1 → 2", 22, T.GOLD, true))
	uv.add_child(ut)
	var ureq := T.lbl("", 14, T.DIM)
	ureq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uv.add_child(ureq)
	var uunl := T.lbl("", 14, Color(0.75, 0.9, 1.0))
	uunl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uv.add_child(uunl)
	var ub := Button.new()
	ub.text = "Улучшить"
	ub.custom_minimum_size = Vector2(0, 44)
	ub.add_theme_font_size_override("font_size", 20)
	ub.pressed.connect(func(): _act("upgrade", ""))
	uv.add_child(ub)
	_upgrade = {"title": ut, "req": ureq, "unl": uunl, "btn": ub}
	# Касса: забрать самому (режим «Хозяин») или вызвать инкассатора
	var tp := T.panel(Color(0.03, 0.09, 0.05, 0.95), T.GOOD, 1, 10)
	v.add_child(tp)
	var tv := VBoxContainer.new()
	tp.add_child(tv)
	var tl := T.lbl("", 16, T.GOOD, true)
	tv.add_child(tl)
	var tn := T.lbl("30%% выручки зала копится в кассе. Заберите сами ([Tab] → к кассе → E) или вызовите инкассатора — он берёт %d%%." % int(Game.INKASSO_FEE * 100), 13, T.DIM)
	tn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(tn)
	var tb := Button.new()
	tb.custom_minimum_size = Vector2(0, 38)
	tb.pressed.connect(func():
		Sfx.play("click", -6.0)
		Game.request({"a": "inkasso"}))
	tv.add_child(tb)
	_till = {"label": tl, "btn": tb}
	v.add_child(_header("Способности", T.GOLD))
	for a in Defs.ABILITIES:
		v.add_child(_card(a.icon, Color(0.4, 0.85, 1.0), a.name, a.desc, "ability", a.id, "Перезарядка %d с" % a.cd))
	v.add_child(_header("Почему клиенты выбирают казино", T.GOLD))
	_breakdown = RichTextLabel.new()
	_breakdown.bbcode_enabled = true
	_breakdown.fit_content = true
	_breakdown.scroll_active = false
	v.add_child(_breakdown)
	v.add_child(_header("Статистика", T.GOLD))
	_stats = RichTextLabel.new()
	_stats.bbcode_enabled = true
	_stats.fit_content = true
	_stats.scroll_active = false
	v.add_child(_stats)
	return s[0]


func _header(text: String, c: Color) -> Control:
	var l := T.shadowed(T.lbl(text.to_upper(), 15, c, true), 4)
	l.add_theme_constant_override("line_spacing", 0)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 6)
	m.add_child(l)
	return m


func _tab_list(title: String, kind: String) -> Control:
	var s := _scroll(title)
	var v: VBoxContainer = s[1]
	var src: Array = Defs.FACILITIES if kind == "build" else Defs.DEFENSES
	var last_lvl := -1
	if kind == "defense":
		var note := T.lbl("Защита стоит денег каждую минуту, но ловит пакостников и смягчает удары.", 14, T.DIM)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(note)
	for f in src:
		if kind == "build" and f.lvl != last_lvl:
			last_lvl = f.lvl
			v.add_child(_header("Уровень %d" % f.lvl, Color(0.75, 0.6, 1.0)))
		v.add_child(_card(f.icon, f.col, f.name, f.desc, kind, f.id, _info(kind, f)))
	return s[0]


func _tab_sabotage() -> Control:
	var s := _scroll("Пакости")
	var v: VBoxContainer = s[1]
	_sab_risk_note = T.lbl("", 14, T.DIM)
	_sab_risk_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_sab_risk_note)
	var last_tier := -1
	for sb in Defs.SABOTAGES:
		if sb.tier != last_tier:
			last_tier = sb.tier
			v.add_child(_header(Defs.TIER_NAMES[sb.tier], Defs.TIER_COLORS[sb.tier]))
		v.add_child(_card(sb.icon, Defs.TIER_COLORS[sb.tier], sb.name, sb.desc, "sabotage", sb.id, ""))
	return s[0]


func _info(kind: String, f: Dictionary) -> String:
	var parts := []
	if kind == "build":
		if f.has("attract"):
			parts.append("+%d привлек." % f.attract)
		if f.has("cap"):
			parts.append("+%d мест" % f.cap)
		if f.has("spend"):
			parts.append("+%d%% трат" % int(f.spend * 100))
		if f.has("comfort"):
			parts.append("+%d комфорт" % f.comfort)
		if f.has("music"):
			parts.append("+%d музыка" % f.music)
		if f.has("smell"):
			parts.append("+%d запах" % f.smell)
		if f.has("passive"):
			parts.append("+$%d/с" % int(f.passive))
		if f.has("stay"):
			parts.append("клиенты дольше +%d%%" % int(f.stay * 100))
		for k in f.get("prefs", {}):
			parts.append("%s +%d" % [Defs.CLIENTS[k].name, f.prefs[k]])
	else:
		parts.append("Содержание $%d/мин" % f.upkeep)
		if f.has("catch"):
			parts.append("+%d%% поимка" % int(f.catch * 100))
	return " • ".join(parts)


func _card(icon: String, ic: Color, title: String, desc: String, kind: String, id: String, info: String) -> Control:
	var pc := PanelContainer.new()
	var st := T.box(Color(0.09, 0.06, 0.14, 0.97), Color(ic.r, ic.g, ic.b, 0.5), 1, 9, 8)
	st.border_width_left = 4
	pc.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	pc.add_child(h)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(54, 54)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	badge.add_theme_stylebox_override("panel", T.box(Color(ic.r * 0.3, ic.g * 0.3, ic.b * 0.3), ic, 2, 10, 2))
	var bl := T.lbl(icon, 20 if icon.length() <= 2 else (15 if icon.length() <= 3 else 11), ic.lightened(0.35), true)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var tl := T.lbl(title, 16, T.TEXT, true)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tl)
	var dl := T.lbl(desc, 13, T.DIM)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(dl)
	var il := T.lbl(info, 13, ic.lightened(0.25))
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(il)
	var b := Button.new()
	b.custom_minimum_size = Vector2(100, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): _act(kind, id))
	h.add_child(b)
	_cards.append({"pc": pc, "btn": b, "info": il, "kind": kind, "id": id, "base_info": info})
	return pc


func _act(kind: String, id: String) -> void:
	if not Game.running:
		return
	var err := Game.can(my, role, kind, id)
	if err != "":
		_on_toast(err, "bad")
		Sfx.play("error")
		return
	Sfx.play("click")
	Game.request({"a": kind, "id": id})


# =============================================================================
# Лента событий, чат, нижние кнопки
# =============================================================================
func _build_feed() -> void:
	var p := T.panel(Color(0.03, 0.02, 0.05, 0.78), Color(T.GOLD.r, T.GOLD.g, T.GOLD.b, 0.2), 1, 8)
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = 10
	p.offset_right = 600
	p.offset_top = -300
	p.offset_bottom = -62
	_root.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var hdr := T.lbl("НОВОСТИ УЛИЦЫ", 13, T.GOLD, true)
	v.add_child(hdr)
	_feed = RichTextLabel.new()
	_feed.bbcode_enabled = true
	_feed.scroll_following = true
	_feed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feed.add_theme_font_size_override("normal_font_size", 14)
	v.add_child(_feed)
	_chat = LineEdit.new()
	_chat.placeholder_text = "Enter — написать в чат" if Net.online else "Enter — заметка себе (в сетевой игре — чат)"
	_chat.add_theme_font_size_override("font_size", 14)
	_chat.text_submitted.connect(_on_chat_submit)
	v.add_child(_chat)


func _build_bottom() -> void:
	var h := HBoxContainer.new()
	h.anchor_left = 0.0
	h.anchor_right = 1.0
	h.anchor_top = 1.0
	h.anchor_bottom = 1.0
	h.offset_left = 10
	h.offset_right = -10
	h.offset_top = -52
	h.offset_bottom = -8
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(h)
	_bottom = h
	_fp_btn = Button.new()
	_fp_btn.text = "[Tab] Выйти на улицу"
	_fp_btn.focus_mode = Control.FOCUS_NONE
	_fp_btn.pressed.connect(func(): _toggle_fp())
	h.add_child(_fp_btn)
	for b in [["[1] Моё казино", "own"], ["[2] Соседи", "enemy"], ["[3] Обзор", "overview"]]:
		var btn := Button.new()
		btn.text = b[0]
		var p: String = b[1]
		btn.pressed.connect(func(): _cam(p))
		btn.focus_mode = Control.FOCUS_NONE
		h.add_child(btn)
	var hint := T.lbl("   ПКМ — вращать • Колесо — зум • WASD — двигать • Q/E — поворот", 13, T.DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(hint)
	for b in [["[F1] Помощь", "help"], ["[Esc] Меню", "menu"]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.focus_mode = Control.FOCUS_NONE
		var w: String = b[1]
		btn.pressed.connect(func(): _toggle(w))
		h.add_child(btn)


func _cam(p: String) -> void:
	if fp_on:
		_toggle_fp()
	if cam:
		cam.preset(p, my)
	Sfx.play("click", -8.0)


# =============================================================================
# Режим «Хозяин» (от первого лица)
# =============================================================================
const FP_HINT := "WASD — идти • Shift — бег • Пробел — прыжок • E — действие (держать — долгое) • ЛКМ — удар • V — вид со спины • B — планшет • Tab — карта"


func _build_fp() -> void:
	_fp_layer = Control.new()
	_fp_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_layer.visible = false
	_root.add_child(_fp_layer)
	_root.move_child(_fp_layer, 0)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.9, 0.05, 0.05, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_layer.add_child(_flash)
	var cross := Control.new()
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fp_layer.add_child(cross)
	for r in [Rect2(-9, -1, 6, 2), Rect2(3, -1, 6, 2), Rect2(-1, -9, 2, 6), Rect2(-1, 3, 2, 6)]:
		var c := ColorRect.new()
		c.position = r.position
		c.size = r.size
		c.color = Color(1, 1, 1, 0.85)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross.add_child(c)
	_prompt = T.shadowed(T.lbl("", 20, T.TEXT, true), 8)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.offset_left = -420
	_prompt.offset_right = 420
	_prompt.offset_top = 40
	_prompt.offset_bottom = 72
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fp_layer.add_child(_prompt)
	_hold_bar = ProgressBar.new()
	_hold_bar.set_anchors_preset(Control.PRESET_CENTER)
	_hold_bar.offset_left = -130
	_hold_bar.offset_right = 130
	_hold_bar.offset_top = 82
	_hold_bar.offset_bottom = 96
	_hold_bar.max_value = 1.0
	_hold_bar.show_percentage = false
	_hold_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = T.GOLD
	fill.set_corner_radius_all(4)
	_hold_bar.add_theme_stylebox_override("background", bg)
	_hold_bar.add_theme_stylebox_override("fill", fill)
	_fp_layer.add_child(_hold_bar)
	var hint := T.shadowed(T.lbl(FP_HINT, 14, Color(1, 1, 1, 0.8)), 5)
	hint.anchor_left = 0.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.offset_left = 620
	hint.offset_right = -14
	hint.offset_top = -52
	hint.offset_bottom = -8
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fp_layer.add_child(hint)
	_ko = ColorRect.new()
	_ko.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ko.color = Color(0.05, 0.0, 0.08, 0.7)
	_ko.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ko.visible = false
	_fp_layer.add_child(_ko)
	_ko_label = T.shadowed(T.lbl("", 46, T.BAD, true), 10)
	_ko_label.set_anchors_preset(Control.PRESET_CENTER)
	_ko_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ko_label.offset_left = -500
	_ko_label.offset_right = 500
	_ko_label.offset_top = -60
	_ko_label.offset_bottom = 60
	_ko.add_child(_ko_label)


func _toggle_fp() -> void:
	if match_node and _end == null:
		match_node.set_fp(not fp_on)
		Sfx.play("click", -8.0)


func set_fp(on: bool) -> void:
	fp_on = on
	tablet = false
	_fp_layer.visible = on
	_side.visible = not on
	_fp_btn.text = "[Tab] Карта" if on else "[Tab] Выйти на улицу"
	for c in _bottom.get_children():
		c.visible = not on or c == _fp_btn
	if on:
		_on_toast("Вы на улице! E — касса, починка и пакости соседу, ЛКМ — удар, B — планшет", "info")


func _update_fp() -> void:
	var overlays := _pause.visible or _help.visible or _end != null or _chat.has_focus()
	var want_capture := fp_on and not tablet and not overlays
	var mode := Input.MOUSE_MODE_CAPTURED if want_capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode and DisplayServer.get_name() != "headless":
		Input.mouse_mode = mode
	if player == null:
		return
	player.controls = want_capture
	if not fp_on:
		return
	_side.visible = tablet
	var f: Dictionary = player.focus
	_prompt.text = String(f.get("prompt", ""))
	var c := T.TEXT
	if not bool(f.get("ok", true)):
		c = T.DIM
	elif bool(f.get("bad", false)):
		c = Color(1.0, 0.6, 0.35)
	elif String(f.get("op", "")) in ["collect", "fix"]:
		c = T.GOOD
	_prompt.add_theme_color_override("font_color", c)
	_hold_bar.visible = player.hold > 0.0
	_hold_bar.value = player.hold
	_ko.visible = player.ko_t > 0.0
	if _ko.visible:
		_ko_label.text = "НОКАУТ!\nОчнётесь через %d…" % ceili(player.ko_t)
	_flash.color.a = clampf(player.flash, 0.0, 1.0) * 0.45


# =============================================================================
# Обновление
# =============================================================================
func _process(delta: float) -> void:
	_update_fp()
	if Game.teams.size() == 2:
		_timer.text = Defs.time_str(Game.time_left)
		if Game.time_left < 60.0 and Game.running:
			_timer.add_theme_color_override("font_color", T.BAD if fmod(Game.time_left, 1.0) > 0.5 else T.GOLD)


func _refresh() -> void:
	if Game.teams.size() != 2:
		return
	for t in 2:
		var st: Dictionary = Game.teams[t]
		var ui: Dictionary = _top[t]
		ui.lvl.text = "УР. %d" % st.level
		ui.money.text = Defs.money(st.money)
		ui.money.add_theme_color_override("font_color", Color(1, 0.88, 0.4) if st.money >= 0 else T.BAD)
		var inc: float = st.income
		ui.income.text = ("+" if inc >= 0 else "") + Defs.money(inc) + "/мин"
		ui.income.add_theme_color_override("font_color", T.GOOD if inc >= 0 else T.BAD)
		ui.rep.value = st.rep
		var fill := T.box(Color(1, 0.3, 0.3).lerp(Color(0.4, 1, 0.5), st.rep / 100.0), Color(0, 0, 0, 0), 0, 6, 0)
		ui.rep.add_theme_stylebox_override("fill", fill)
		ui.crowd.text = "Внутри %d/%d • Очередь %d" % [st.inside, st.cap, st.queue]
		var chips: HFlowContainer = ui.chips
		for c in chips.get_children():
			c.free()
		# Не больше 4 плашек, остальное — счётчиком, чтобы панель не раздувалась.
		var items := []
		for e in st.effects:
			if Defs.sab_by_id.has(e):
				items.append(["%s %dс" % [Defs.sab_by_id[e].name, ceili(st.effects[e])], T.BAD])
		for b in st.buffs:
			items.append(["%s %dс" % [Game.BUFF_NAMES.get(b, b), ceili(st.buffs[b])], T.GOOD])
		if st.get("warn_bankrupt", false):
			items.push_front(["ДОЛГИ! БАНКРОТСТВО БЛИЗКО", T.BAD])
		for i in mini(items.size(), 4):
			chips.add_child(_chip(items[i][0], items[i][1]))
		if items.size() > 4:
			chips.add_child(_chip("ещё +%d" % (items.size() - 4), T.GOLD))
		var names := []
		for p in Net.players.values():
			if int(p.team) == t:
				var r := ""
				if p.role != "boss":
					r = " (%s)" % Defs.ROLES[p.role].name
				names.append(String(p.name) + r)
		if Game.is_ai(t):
			names.append("ИИ-бот")
		ui.players.text = "Управляют: " + ", ".join(names)
	var s0 := float(maxi(Game.score(0), 1))
	var s1 := float(maxi(Game.score(1), 1))
	var w := _score_bar.size.x
	var k := s0 / (s0 + s1)
	_score_bar_l.size = Vector2(w * k, 14)
	_score_bar_r.position = Vector2(w * k, 0)
	_score_bar_r.size = Vector2(w * (1.0 - k), 14)
	_score_l.text = "Империя: %s  vs  %s" % [Defs.money(Game.score(0)), Defs.money(Game.score(1))]
	var rv: int = Game.teams[my].revenge
	_revenge.text = ("ОТВЕТНЫЙ УДАР ×%d: следующая пакость −50%% и без риска!" % rv) if rv > 0 else ""
	_refresh_cards()


func _refresh_cards() -> void:
	var st: Dictionary = Game.teams[my]
	var est: Dictionary = Game.teams[en]
	var till := float(st.get("till", 0.0))
	var full := till >= float(st.get("till_cap", 1.0)) - 0.5
	_till.label.text = ("КАССА ПОЛНА: %s — больше не копится!" if full else "В кассе: %s") % Defs.money(till)
	_till.label.add_theme_color_override("font_color", T.BAD if full else T.GOOD)
	_till.btn.text = "Инкассатор: +%s" % Defs.money(till * (1.0 - Game.INKASSO_FEE))
	_till.btn.disabled = till < 1.0
	for c in _cards:
		var err := Game.can(my, role, c.kind, c.id)
		var price := Game.price(my, role, c.kind, c.id)
		var b: Button = c.btn
		var pc: Control = c.pc
		pc.modulate = Color.WHITE
		b.remove_theme_color_override("font_disabled_color")
		if err == "":
			b.disabled = false
			b.text = Defs.money(price)
		elif err == "Построено" or err == "Нанят":
			b.disabled = true
			b.text = "ЕСТЬ"
			b.add_theme_color_override("font_disabled_color", T.GOOD)
		elif err.begins_with("Нужен ур."):
			b.disabled = true
			b.text = err.replace("Нужен ", "")
			pc.modulate = Color(1, 1, 1, 0.5)
		elif err == "Мало денег":
			b.disabled = true
			b.text = Defs.money(price)
			b.add_theme_color_override("font_disabled_color", Color(1, 0.45, 0.45))
		else:
			b.disabled = true
			b.text = err.replace("Ждать ", "")
		b.tooltip_text = "" if err == "" else err
		if c.kind == "sabotage":
			var sb: Dictionary = Defs.sab_by_id[c.id]
			var parts := []
			if sb.get("self", false):
				parts.append("Без риска")
			else:
				var risk := _risk(sb)
				parts.append("Риск поимки %d%%" % int(risk * 100))
			if sb.dur > 0:
				parts.append("%d с" % sb.dur)
			parts.append("Перезарядка %d с" % sb.cd)
			c.info.text = " • ".join(parts)
	# Улучшение
	var lvl: int = st.level
	if lvl >= Defs.MAX_LEVEL:
		_upgrade.title.text = "Уровень 10 — МАКСИМУМ"
		_upgrade.req.text = "Вы на вершине пищевой цепи. Тотальные саботажи открыты."
		_upgrade.unl.text = ""
		_upgrade.btn.disabled = true
		_upgrade.btn.text = "МАКСИМУМ"
	else:
		_upgrade.title.text = "Уровень %d → %d" % [lvl, lvl + 1]
		var err := Game.can(my, role, "upgrade")
		_upgrade.req.text = "Условие: построить хотя бы один объект уровня %d. %s" % [lvl, "Выполнено." if Game._tier_done(my) else "Не выполнено!"]
		var unl := []
		for f in Defs.FACILITIES:
			if f.lvl == lvl + 1:
				unl.append(f.name)
		for d in Defs.DEFENSES:
			if d.lvl == lvl + 1:
				unl.append(d.name)
		for sb in Defs.SABOTAGES:
			if sb.lvl == lvl + 1:
				unl.append("пакость «%s»" % sb.name)
		_upgrade.unl.text = "Откроется: " + (", ".join(unl) if not unl.is_empty() else "рост здания и престиж")
		_upgrade.btn.disabled = err != ""
		_upgrade.btn.text = "Улучшить за %s" % Defs.money(Game.price(my, role, "upgrade")) if err == "" or err == "Мало денег" else err
	# Разбор привлекательности
	var bd: Dictionary = st.get("breakdown", {})
	var ebd: Dictionary = est.get("breakdown", {})
	var txt := "[table=3][cell][color=#9a90b0]Фактор[/color]  [/cell][cell][color=#%s]Мы[/color]  [/cell][cell][color=#%s]Соседи[/color][/cell]" % [T.hex(Defs.TEAM_COLORS[my]), T.hex(Defs.TEAM_COLORS[en])]
	var tot_a := 0.0
	var tot_b := 0.0
	for k in bd:
		var a: float = bd[k]
		var bb: float = ebd.get(k, 0.0)
		tot_a += a
		tot_b += bb
		txt += "[cell]%s  [/cell][cell]%s  [/cell][cell]%s[/cell]" % [k, _num(a, bb), _num(bb, a)]
	txt += "[cell][b]ИТОГО[/b]  [/cell][cell][b]%s[/b]  [/cell][cell][b]%s[/b][/cell][/table]" % [_num(tot_a, tot_b), _num(tot_b, tot_a)]
	_breakdown.text = txt
	var ss: Dictionary = st.stats
	_stats.text = "Клиентов обслужено: [b]%d[/b]\nЗаработано: [b]%s[/b]\nПакостей удалось: [b]%d[/b], попались: [b]%d[/b]\nПоймали соседей: [b]%d[/b]" % [
		ss.clients, Defs.money(ss.earned), ss.sab_ok, ss.sab_caught, ss.caught_enemy]
	var defs := []
	for d in Defs.DEFENSES:
		if est.defense.has(d.id):
			defs.append(d.name)
	_sab_risk_note.text = "Если поймают — штраф 50%% цены, минус репутация, а соседи получают право на ответный удар. Защита соседей: %s.%s" % [
		", ".join(defs) if not defs.is_empty() else "никакой (самое время!)", " Вы — Пакостник: дешевле и незаметнее." if role == "saboteur" else ""]


func _num(a: float, b: float) -> String:
	var c := "#8cff9a" if a > b + 0.5 else ("#ff7070" if a < b - 0.5 else "#e0dcea")
	return "[color=%s]%+d[/color]" % [c, int(round(a))]


func _risk(sb: Dictionary) -> float:
	if Game.teams[my].revenge > 0:
		return 0.0
	var ch: float = sb.catch
	for d in Defs.DEFENSES:
		if Game.teams[en].defense.has(d.id):
			ch += float(d.get("catch", 0.0))
	if role == "saboteur":
		ch -= 0.07
	return clampf(ch, 0.03, 0.85)


# =============================================================================
# События
# =============================================================================
func _on_event(text: String, kind: String, good_team: int) -> void:
	var c := "#d8d2e6"
	var good := good_team == my
	match kind:
		"build":
			c = "#9fd8ff" if good else "#b9a9d6"
		"good":
			c = "#8cff9a" if good else "#d0c0a0"
		"big":
			c = "#ffc847"
		"sabotage":
			c = "#8cff9a" if good else "#ff6b6b"
		"caught":
			c = "#8cff9a" if good else "#ff4040"
		"info":
			c = "#b0a8c0"
	_add_feed("[color=%s]%s[/color]" % [c, text.replace("[", "[lb]")])
	if kind in ["caught", "sabotage", "big"]:
		_on_toast(text, ("good" if good else "bad") if kind != "big" else "big")
		if kind != "big" and cam and not good:
			cam.shake(0.8)


func _add_feed(bb: String) -> void:
	var tm := Defs.time_str(Game.elapsed)
	_feed_lines.append("[color=#6f6680]%s[/color] %s" % [tm, bb])
	if _feed_lines.size() > 60:
		_feed_lines.pop_front()
	_feed.text = "\n".join(_feed_lines)


func _on_chat(sender: String, team: int, text: String) -> void:
	if sender == "":
		_add_feed("[color=#8a80a0][i]%s[/i][/color]" % text.replace("[", "[lb]"))
		return
	var c := T.hex(Defs.TEAM_COLORS[team]) if team >= 0 else "ffffff"
	_add_feed("[color=#%s][b]%s:[/b][/color] %s" % [c, sender.replace("[", "[lb]"), text.replace("[", "[lb]")])
	Sfx.play("chat", -6.0)


func _on_chat_submit(text: String) -> void:
	Game.send_chat(text)
	_chat.text = ""
	_chat.release_focus()


func _on_toast(text: String, kind: String) -> void:
	var c := T.GOLD
	match kind:
		"bad":
			c = T.BAD
		"good":
			c = T.GOOD
	var p := T.panel(Color(0.05, 0.02, 0.08, 0.92), c, 2, 10)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := T.shadowed(T.lbl(text, 18, c.lightened(0.2), true))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(560, 0)
	p.add_child(l)
	_toasts.add_child(p)
	while _toasts.get_child_count() > 3:
		_toasts.get_child(0).free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


# =============================================================================
# Пауза, помощь, конец матча
# =============================================================================
func _overlay() -> Control:
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, 0.6)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.visible = false
	_root.add_child(o)
	return o


func _center_panel(parent: Control, w: float) -> VBoxContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	var p := T.panel(Color(0.06, 0.035, 0.1, 0.98), T.GOLD, 2, 22)
	p.custom_minimum_size = Vector2(w, 0)
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	return v


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	parent.add_child(b)
	return b


func _build_pause() -> void:
	_pause = _overlay()
	var v := _center_panel(_pause, 440)
	var t := T.shadowed(T.lbl("ПАУЗА" if not Net.online else "МЕНЮ", 34, T.GOLD, true))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if Net.online:
		var n := T.lbl("В сетевой игре время не останавливается.", 14, T.DIM)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
	_btn(v, "Продолжить", func(): _toggle("menu"))
	v.add_child(T.lbl("Качество графики", 15, T.DIM))
	var q := OptionButton.new()
	for s in ["Низкое (слабый ПК)", "Среднее", "Высокое"]:
		q.add_item(s)
	q.selected = Defs.quality
	q.item_selected.connect(func(i):
		Defs.quality = i
		Defs.save_settings()
		Defs.apply_settings())
	v.add_child(q)
	v.add_child(T.lbl("Громкость", 15, T.DIM))
	var vol := HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.value = Defs.volume
	vol.value_changed.connect(func(x):
		Defs.volume = x
		Defs.save_settings()
		Defs.apply_settings())
	v.add_child(vol)
	var fs := CheckBox.new()
	fs.text = "Полный экран"
	fs.button_pressed = Defs.fullscreen
	fs.toggled.connect(func(on):
		Defs.fullscreen = on
		Defs.save_settings()
		Defs.apply_settings())
	v.add_child(fs)
	var sur := _btn(v, "Сдаться", func(): pass)
	sur.pressed.connect(func():
		if sur.text == "Точно сдаться?":
			Game.request({"a": "surrender"})
			_toggle("menu")
		else:
			sur.text = "Точно сдаться?")
	_btn(v, "Выйти в главное меню", _to_menu)


func _build_help() -> void:
	_help = _overlay()
	var v := _center_panel(_help, 860)
	var t := T.shadowed(T.lbl("КАК ИГРАТЬ", 30, T.GOLD, true))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size = Vector2(800, 0)
	r.text = HELP_TEXT
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(820, 600)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(r)
	v.add_child(sc)
	_btn(v, "Понятно, идём пакостить", func(): _toggle("help"))


const HELP_TEXT := """[color=#ffc847][b]Цель:[/b][/color] к концу таймера иметь «Империю» больше соседской (деньги + 60% вложений + репутация × 300). Или довести соседа до банкротства.

[color=#ffc847][b]Клиенты[/b][/color] гуляют по улице и выбирают, куда зайти: фасад, вывеска, музыка, запахи, комфорт, репутация, слухи, очередь. Смотрите вкладку «Казино», чтобы понять, почему выбирают не вас.
• [b]VIP[/b] тратят много, но не терпят очередей и плохой репутации. [b]Семьи[/b] любят ресторан и туалет, ненавидят тараканов.
• [b]Пьяные[/b] идут в бар и иногда позорят казино. [b]Шулеры[/b] воруют деньги — их ловят камеры и охрана.

[color=#ffc847][b]Развитие:[/b][/color] стройте объекты и повышайте уровень (до 10). Для повышения нужен хотя бы один объект текущего уровня. Чем выше уровень, тем выше здание и больше людей на улице.

[color=#ff6b6b][b]Пакости:[/b][/color] у каждой есть риск поимки. Попались — штраф, минус репутация, а у соседа «ответный удар» (−50% и без риска). Защита соседа повышает риск. На 10 уровне — Тотальные саботажи.

[color=#8cff9a][b]Защита:[/b][/color] камеры, охрана, детектив ловят. Чистильщик, юрист и PR смягчают удары. Экстренная уборка и PR-кампания снимают эффекты.

[color=#9fd8ff][b]Управление (карта):[/b][/color] ПКМ — вращать камеру, колесо — зум, WASD/СКМ — двигать, Q/E — поворот, [b]1/2/3[/b] — моё казино / соседи / обзор, [b]Enter[/b] — чат, [b]F1[/b] — помощь, [b]Esc[/b] — меню.

[color=#ffc847][b]Режим «Хозяин» — [Tab]:[/b][/color] выйдите на улицу от первого лица. WASD, Shift — бег, пробел — прыжок, V — вид со спины, [b]B[/b] — планшет со стройкой и пакостями.
• [b]Касса:[/b] 30% выручки зала копится в кассе у дальней стены. Подойдите и нажмите E. Полная касса больше не копит!
• [b]Починка руками:[/b] тараканы — у дверей, вонь — у кондиционера, музыка — у щитка, потоп — у двери WC. Держите E — бесплатно и +1 репутации.
• [b]Пакости руками:[/b] у казино соседа — тараканы под дверь, рыба в кондиционер, щиток. Вдвое дешевле пульта, но если рядом хозяин-сосед — риск +30%.
• [b]Касса соседа:[/b] держите E у его кассы — унесёте половину. Камеры, охрана и детектив ловят. Поймали — штраф и вас вышвырнут на дорогу.
• [b]Флаер[/b] (E у прохожего, $15) — человек пойдёт к вам. [b]ЛКМ[/b] — подзатыльник: прохожий убежит, сосед после трёх ударов — в нокауте. На дороге смотрите по сторонам — машины сбивают."""


func _toggle(which: String) -> void:
	var panel := _pause if which == "menu" else _help
	var other := _help if which == "menu" else _pause
	other.visible = false
	panel.visible = not panel.visible
	if not Net.online:
		get_tree().paused = _pause.visible or _help.visible


func _to_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	Net.close()
	Game.stop()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")


func _on_over(r: Dictionary) -> void:
	_pause.visible = false
	_help.visible = false
	_end = _overlay()
	_end.visible = true
	var v := _center_panel(_end, 720)
	var w: int = r.winner
	var title := "НИЧЬЯ" if w < 0 else ("ПОБЕДА!" if w == my else "ПОРАЖЕНИЕ")
	var c := T.GOLD if w < 0 else (T.GOOD if w == my else T.BAD)
	var tl := T.shadowed(T.lbl(title, 54, c, true), 10)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var rl := T.lbl(String(r.reason), 18, T.TEXT)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(rl)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var rows := [["", Defs.TEAM_NAMES[0], Defs.TEAM_NAMES[1]],
		["Империя", Defs.money(r.scores[0]), Defs.money(r.scores[1])],
		["Уровень", str(r.levels[0]), str(r.levels[1])],
		["Деньги", Defs.money(r.money[0]), Defs.money(r.money[1])],
		["Репутация", str(int(r.rep[0])), str(int(r.rep[1]))],
		["Заработано", Defs.money(r.stats[0].earned), Defs.money(r.stats[1].earned)],
		["Клиентов", str(r.stats[0].clients), str(r.stats[1].clients)],
		["Пакостей удалось", str(r.stats[0].sab_ok), str(r.stats[1].sab_ok)],
		["Пойман на пакостях", str(r.stats[0].sab_caught), str(r.stats[1].sab_caught)]]
	for i in rows.size():
		for j in 3:
			var col: Color = T.DIM if j == 0 else (Defs.TEAM_COLORS[j - 1] if i == 0 else T.TEXT)
			grid.add_child(T.lbl(rows[i][j], 17 if i > 0 else 19, col, i == 0 or j == 0))
	_btn(v, "В главное меню", _to_menu)
	Sfx.play("win" if w == my else "lose")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	if _chat.has_focus():
		if k == KEY_ESCAPE:
			_chat.release_focus()
			get_viewport().set_input_as_handled()
		return
	match k:
		KEY_ESCAPE:
			if tablet:
				tablet = false
			elif _end == null:
				_toggle("menu")
		KEY_TAB:
			_toggle_fp()
		KEY_B:
			if fp_on:
				tablet = not tablet
				Sfx.play("phone_open" if tablet else "phone_close", -6.0)
			else:
				return
		KEY_F1:
			_toggle("help")
		KEY_ENTER, KEY_KP_ENTER:
			_chat.grab_focus()
		KEY_1:
			_cam("own")
		KEY_2:
			_cam("enemy")
		KEY_3:
			_cam("overview")
		_:
			return
	get_viewport().set_input_as_handled()

extends RefCounted
## Общая тема интерфейса: тёмный фиолетовый с золотом, скруглённые панели.

const GOLD := Color(1.0, 0.78, 0.28)
const BG := Color(0.055, 0.035, 0.09, 0.93)
const BG2 := Color(0.1, 0.065, 0.16, 0.96)
const TEXT := Color(0.94, 0.92, 0.98)
const DIM := Color(0.68, 0.64, 0.76)
const GOOD := Color(0.45, 1.0, 0.55)
const BAD := Color(1.0, 0.38, 0.38)

static var title_font: Font
static var body_font: Font


static func fonts() -> void:
	if title_font == null:
		title_font = load("res://fonts/RussoOne-Regular.ttf")
		body_font = load("res://fonts/Rubik.ttf")


static func box(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 10, pad := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.anti_aliasing = true
	return s


static func make() -> Theme:
	fonts()
	var t := Theme.new()
	t.default_font = body_font
	t.default_font_size = 17
	t.set_color("font_color", "Label", TEXT)
	var panel := box(BG, Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 2, 12, 12)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# Кнопки
	var bn := box(Color(0.2, 0.1, 0.3), Color(0.6, 0.38, 0.85), 2, 9, 8)
	bn.content_margin_left = 14
	bn.content_margin_right = 14
	var bh := box(Color(0.3, 0.15, 0.42), GOLD, 2, 9, 8)
	bh.content_margin_left = 14
	bh.content_margin_right = 14
	var bp := box(Color(0.42, 0.22, 0.12), GOLD, 2, 9, 8)
	bp.content_margin_left = 14
	bp.content_margin_right = 14
	var bd := box(Color(0.12, 0.11, 0.15, 0.85), Color(0.3, 0.28, 0.34), 2, 9, 8)
	bd.content_margin_left = 14
	bd.content_margin_right = 14
	var bf := box(Color(0, 0, 0, 0), Color(GOLD.r, GOLD.g, GOLD.b, 0.7), 2, 9, 8)
	for cls in ["Button", "OptionButton"]:
		t.set_stylebox("normal", cls, bn)
		t.set_stylebox("hover", cls, bh)
		t.set_stylebox("pressed", cls, bp)
		t.set_stylebox("disabled", cls, bd)
		t.set_stylebox("focus", cls, bf)
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_hover_color", cls, GOLD.lightened(0.3))
		t.set_color("font_pressed_color", cls, Color.WHITE)
		t.set_color("font_disabled_color", cls, Color(0.55, 0.52, 0.6))
		t.set_color("font_focus_color", cls, TEXT)
		t.set_font("font", cls, title_font)
		t.set_font_size("font_size", cls, 16)
	# Поля ввода
	var le := box(Color(0.03, 0.02, 0.06, 0.95), Color(0.5, 0.35, 0.7), 2, 8, 8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", box(Color(0.03, 0.02, 0.06, 0.95), GOLD, 2, 8, 8))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(0.5, 0.47, 0.55))
	t.set_color("caret_color", "LineEdit", GOLD)
	# Вкладки
	var ts := box(Color(0.38, 0.22, 0.08), GOLD, 2, 8, 8)
	ts.corner_radius_bottom_left = 0
	ts.corner_radius_bottom_right = 0
	ts.content_margin_left = 12
	ts.content_margin_right = 12
	var tu := box(Color(0.12, 0.08, 0.18), Color(0.35, 0.25, 0.5), 1, 8, 8)
	tu.corner_radius_bottom_left = 0
	tu.corner_radius_bottom_right = 0
	tu.content_margin_left = 12
	tu.content_margin_right = 12
	var th := tu.duplicate()
	th.bg_color = Color(0.22, 0.12, 0.3)
	t.set_stylebox("tab_selected", "TabContainer", ts)
	t.set_stylebox("tab_unselected", "TabContainer", tu)
	t.set_stylebox("tab_hovered", "TabContainer", th)
	t.set_stylebox("panel", "TabContainer", box(Color(0.04, 0.025, 0.07, 0.6), Color(GOLD.r, GOLD.g, GOLD.b, 0.25), 1, 8, 6))
	t.set_font("font", "TabContainer", title_font)
	t.set_font_size("font_size", "TabContainer", 15)
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", DIM)
	t.set_color("font_hovered_color", "TabContainer", GOLD)
	# Полосы прогресса
	t.set_stylebox("background", "ProgressBar", box(Color(0.02, 0.01, 0.04, 0.9), Color(0.3, 0.25, 0.4), 1, 6, 0))
	t.set_stylebox("fill", "ProgressBar", box(GOLD, Color(0, 0, 0, 0), 0, 6, 0))
	t.set_font_size("font_size", "ProgressBar", 13)
	# Прокрутка
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber", "VScrollBar", box(Color(0.5, 0.35, 0.7, 0.8), Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(GOLD, Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(GOLD, Color(0, 0, 0, 0), 0, 4, 2))
	# Подсказки и меню
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.06, 0.03, 0.1, 0.97), GOLD, 1, 6, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 15)
	t.set_stylebox("panel", "PopupMenu", box(Color(0.08, 0.05, 0.13, 0.98), GOLD, 1, 6, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.35, 0.2, 0.45), Color(0, 0, 0, 0), 0, 4, 4))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 15)
	t.set_font("bold_font", "RichTextLabel", title_font)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", GOLD)
	return t


static func lbl(text: String, size := 17, color := TEXT, title := false) -> Label:
	fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", title_font)
	return l


static func shadowed(l: Label, outline := 6, c := Color(0, 0, 0, 0.8)) -> Label:
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", c)
	return l


static func panel(bg := BG, border := Color(GOLD.r, GOLD.g, GOLD.b, 0.35), bw := 2, pad := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(bg, border, bw, 12, pad)
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 6
	p.add_theme_stylebox_override("panel", s)
	return p


static func hex(c: Color) -> String:
	return c.to_html(false)

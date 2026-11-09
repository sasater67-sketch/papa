extends Node
## Ядро матча. Хост симулирует улицу, экономику, пакости и ИИ, а клиентам рассылает снимки.
## Те же функции can()/price() используются интерфейсом на всех машинах.

signal state_updated
signal ents_updated(data: PackedFloat32Array)
signal event_logged(text: String, kind: String, good_team: int)
signal bubble(id: int, text: String)
signal popup(team: int, text: String, kind: String)
signal fx(team: int, fx_name: String)
signal toast(text: String, kind: String)
signal match_over(result: Dictionary)
signal chat(sender: String, team: int, text: String)
## События для своего игрока от первого лица: нокаут, сбила машина, выкинула охрана и т.п.
signal fp_event(kind: String, data: Dictionary)
signal settings_changed

enum { WALK, GOING, QUEUE, INSIDE, LEAVE }

# Слои физики (общие с китами Jackpot Hotel).
const L_WORLD := 1
const L_PLAYER := 2
const L_NPC := 4
const L_INTERACT := 8
const L_TRIGGER := 16
const C_GOLD := Color(1.0, 0.78, 0.28)
const C_INFO := Color(0.6, 0.85, 1.0)
const C_DIM := Color(0.62, 0.56, 0.72)

# Режим «Хозяин» (от первого лица).
const TILL_SHARE := 0.3      # доля выручки зала, которая копится в кассе
const INKASSO_FEE := 0.25    # инкассатор с пульта забирает четверть
const HIT_KO := 3
const KO_TIME := 5.0
const KO_PROT := 6.0
const FP_STALE_MS := 3000
# Точки взаимодействия в координатах казино: x вдоль фасада, z>0 — участок, z<0 — зал.
const SPOT := {
	"till": Vector3(0.0, 0.0, -8.4),
	"wc": Vector3(7.4, 0.0, -8.6),
	"door": Vector3(0.0, 0.0, 1.0),
	"ac": Vector3(8.3, 0.0, 0.55),
	"panel": Vector3(-8.3, 0.0, 0.45),
}
const FIX_SPOT := {"roaches": "door", "stink": "ac", "music_break": "panel", "plumbing": "wc"}
const HAND_SAB := {"door": "roaches", "ac": "stink", "panel": "music_break"}

## Настройки, которые читают киты Jackpot Hotel.
var settings := {"fov": 75.0, "sensitivity": 0.22, "shake": true}
## Узел мира — для объёмных звуков китов.
var world: Node3D = null
## peer -> {p: Vector3, yaw: float, f: int, t: msec}
var fp := {}
var _hits := {}
var _ko_until := {}
var _fp_cd := {}

const DOOR_Z := 16.0
const WALK_Z := 5.5
const PLAZA_Z := 7.6
const CROSS_X := [-14.0, 14.0]
const END_X := 64.0
const MAX_PEDS := 110
const WALK_BY := 30.0
const POW := 1.7
const PHYSICAL := ["roaches", "stink", "music_break", "plumbing"]
const BUFF_NAMES := {"party": "Коктейли", "grand_raffle": "Розыгрыш", "sign_war_own": "Мега-вывеска", "taxi": "Свои таксисты"}

var running := false
var authority := false
var networked := false
var demo := false
var teams: Array = []
var time_left := 0.0
var elapsed := 0.0
var ai_teams := [false, false]
var result := {}
var last_ents := PackedFloat32Array()


class Ped:
	var id := 0
	var type := "normal"
	var seed := 0
	var pos := Vector2.ZERO
	var path: Array = []
	var speed := 2.0
	var state := 0
	var target := -1
	var decided := false
	var dir := 1
	var side := 0
	var lane := 0.0
	var timer := 0.0
	var spend_rate := 0.0
	var yaw := 0.0
	var patience := 20.0
	var moving := false
	var tag := ""


class Car:
	var id := 0
	var x := 0.0
	var z := 0.0
	var dir := 1
	var speed := 9.0
	var cur := 9.0
	var sub := 0
	var drop_target := -1
	var stop_x := 0.0
	var stop_t := 0.0
	var dropped := false


var peds := {}
var cars := {}
var queues := [[], []]
var _next_id := 1
var _spawn_acc := 0.0
var _car_t := 1.0
var _taxi_t := 5.0
var _sync_acc := 0.0
var _state_acc := 0.0
var _eco_acc := 0.0
var _bubble_cd := 0.0
var _ai_t := [2.0, 3.0]
var _pop_acc := [0.0, 0.0]
var _pop_t := 0.0
var _income_acc := [0.0, 0.0]
var _income_t := 0.0
var _bankrupt := [0.0, 0.0]
var _appeal_cache := [{}, {}]
var _attacked := [0.0, 0.0]


# =============================================================================
# Запуск
# =============================================================================
func _new_team(t: int) -> Dictionary:
	return {
		"name": Defs.TEAM_NAMES[t], "money": float(Defs.START_MONEY), "rep": 50.0, "level": 1,
		"built": {}, "defense": {}, "effects": {}, "buffs": {}, "cd": {},
		"revenge": 0, "inside": 0, "queue": 0, "cap": 8, "income": 0.0, "appeal": 0.0, "breakdown": {},
		"ai": false, "warn_bankrupt": false, "till": 0.0, "till_cap": till_cap_for(1),
		"stats": {"earned": 0.0, "clients": 0, "sab_ok": 0, "sab_caught": 0, "caught_enemy": 0, "invested": 0.0,
			"fixed": 0, "lured": 0, "ko": 0, "stolen": 0.0},
	}


func till_cap_for(level: int) -> float:
	return 450.0 + 380.0 * level


func _reset() -> void:
	teams = [_new_team(0), _new_team(1)]
	peds.clear()
	cars.clear()
	queues = [[], []]
	_next_id = 1
	_spawn_acc = 0.0
	_car_t = 0.5
	_taxi_t = 5.0
	elapsed = 0.0
	result = {}
	_bankrupt = [0.0, 0.0]
	_attacked = [0.0, 0.0]
	last_ents = PackedFloat32Array()
	fp.clear()
	_hits.clear()
	_ko_until.clear()
	_fp_cd.clear()
	for t in 2:
		_appeal_cache[t] = _calc_breakdown(t)


func prepare_match() -> void:
	_reset()
	demo = false
	authority = multiplayer.is_server()
	networked = Net.online
	time_left = float(Net.settings.get("duration", 20)) * 60.0
	on_players_changed()
	running = false


## Вызывается сценой матча, когда мир построен.
func begin() -> void:
	running = true
	if authority:
		for i in 22:
			_spawn_random_ped(randf_range(-END_X + 4, END_X - 4))
		_send_state()


## Фоновый матч ИИ против ИИ для главного меню.
func start_demo() -> void:
	_reset()
	demo = true
	authority = true
	networked = false
	time_left = 1e9
	ai_teams = [true, false]
	ai_teams[1] = true
	for t in 2:
		var st: Dictionary = teams[t]
		st.level = 6
		st.money = 9000.0
		st.rep = 60.0
		for f in Defs.FACILITIES:
			if f.lvl <= 6 and randf() < 0.85:
				st.built[f.id] = true
		st.built["sign"] = true
		for d in Defs.DEFENSES:
			if d.lvl <= 5 and randf() < 0.5:
				st.defense[d.id] = true
	running = true
	for i in 30:
		_spawn_random_ped(randf_range(-END_X + 4, END_X - 4))
	_eco(0.01)
	_send_state()


func stop() -> void:
	running = false
	demo = false
	peds.clear()
	cars.clear()


func on_players_changed() -> void:
	for t in 2:
		var human := false
		for p in Net.players.values():
			if int(p.team) == t:
				human = true
		ai_teams[t] = not human
		if teams.size() == 2:
			teams[t].ai = not human


func is_ai(t: int) -> bool:
	return teams.size() == 2 and bool(teams[t].get("ai", false))


# =============================================================================
# Главный цикл (только у хоста)
# =============================================================================
func _process(delta: float) -> void:
	if not running or not authority:
		return
	var dt := minf(delta, 0.1)
	elapsed += dt
	if not demo:
		time_left -= dt
		if time_left <= 0.0:
			_end_by_time()
			return
	_bubble_cd -= dt
	_update_spawns(dt)
	_update_peds(dt)
	_update_cars(dt)
	_update_queues()
	_eco_acc += dt
	if _eco_acc >= 0.5:
		_eco(_eco_acc)
		_eco_acc = 0.0
	for t in 2:
		if ai_teams[t]:
			_ai(t, dt)
	_sync_acc += dt
	if _sync_acc >= 1.0 / 15.0:
		_sync_acc = 0.0
		_send_ents()
	_state_acc += dt
	if _state_acc >= 0.2:
		_state_acc = 0.0
		_send_state()


# =============================================================================
# Геометрия
# =============================================================================
func sgn(t: int) -> float:
	return -1.0 if t == 0 else 1.0


func door_pos(t: int) -> Vector2:
	return Vector2(0, sgn(t) * DOOR_Z)


func queue_spot(t: int, i: int) -> Vector2:
	return Vector2(0.35 * (i % 2) - 0.15, sgn(t) * (DOOR_Z - 1.4 - i * 0.8))


# =============================================================================
# Расчёты (работают и у клиентов по синхронизированным данным)
# =============================================================================
func has(t: int, id: String) -> bool:
	return teams[t].built.has(id) or teams[t].defense.has(id)


func has_eff(t: int, id: String) -> bool:
	return teams[t].effects.has(id)


func has_buff(t: int, id: String) -> bool:
	return teams[t].buffs.has(id)


func fac_sum(t: int, key: String) -> float:
	var s := 0.0
	for id in teams[t].built:
		s += float(Defs.fac_by_id[id].get(key, 0))
	return s


func capacity(t: int) -> int:
	var c: float = 6.0 + fac_sum(t, "cap") + teams[t].level * 2
	if has_eff(t, "plumbing"):
		c *= 0.7
	return int(c)


func spend_mult(t: int) -> float:
	# Уровень казино = более крупные ставки.
	var m: float = (1.0 + fac_sum(t, "spend")) * (1.0 + 0.45 * (teams[t].level - 1))
	if has_eff(t, "fakemoney"):
		m *= 0.8 if has(t, "guards") else 0.6
	if has_eff(t, "black_monday"):
		m *= 0.3
	if has_eff(t, "dealer_bribe"):
		m *= 0.6
	return m


func _calc_breakdown(t: int) -> Dictionary:
	var st: Dictionary = teams[t]
	var b := {}
	var facade: float = 8.0 + fac_sum(t, "attract") + st.level * 3.0
	var music := fac_sum(t, "music")
	var smell := fac_sum(t, "smell")
	var comfort := fac_sum(t, "comfort") * 0.5
	var buzz := 4.0 if has(t, "pr") else 0.0
	var promo := 0.0
	var pr_k := 0.5 if has(t, "pr") else 1.0
	# Пакости и акции масштабируются с уровнем, чтобы оставаться ощутимыми у богатых казино.
	var k: float = 1.0 + 0.15 * (st.level - 1)
	if has_eff(t, "roaches"):
		comfort -= 10.0 * k
	if has_eff(t, "stink"):
		smell -= 14.0 * k
	if has_eff(t, "music_break"):
		music = -8.0 * k - music * 0.5
	if has_eff(t, "rumor"):
		buzz -= 15.0 * pr_k * k
	if has_eff(t, "news"):
		buzz -= 12.0 * pr_k * k
	if has_eff(t, "plumbing"):
		comfort -= 12.0 * k
	if has_eff(t, "exodus"):
		buzz -= 20.0 * k
	if has_eff(t, "black_monday"):
		facade -= 10.0 * k
	if has_eff(t, "sign_war"):
		facade -= 20.0 * k
	if has_buff(t, "sign_war_own"):
		facade += 20.0 * k
	if has_buff(t, "party"):
		promo += 15.0 * k
	if has_buff(t, "grand_raffle"):
		promo += 30.0 * k
	b["Фасад"] = facade
	b["Музыка"] = music
	b["Запахи"] = smell
	b["Комфорт"] = comfort
	b["Репутация"] = (st.rep - 50.0) * 0.5 * k
	b["Слухи"] = buzz
	b["Акции"] = promo
	b["Очередь"] = -queues[t].size() * 1.5 if authority else -float(st.queue) * 1.5
	# Публика жалеет отстающего — без этого лидер забирает всю улицу.
	var mine := float(maxi(score(t), 1))
	var other := float(maxi(score(1 - t), 1))
	b["Сочувствие"] = clampf((other / mine - 1.15) * 10.0, 0.0, 25.0) * k
	return b


func appeal(t: int, type: String) -> float:
	var b: Dictionary = _appeal_cache[t]
	var s := 0.0
	for k in b:
		s += b[k]
	for id in teams[t].built:
		s += float(Defs.fac_by_id[id].get("prefs", {}).get(type, 0))
	match type:
		"family":
			if has_eff(t, "roaches"):
				s -= 15.0
			if has_eff(t, "stink"):
				s -= 8.0
			s += b["Комфорт"]
		"vip":
			if teams[t].rep < 35.0:
				s -= 30.0
			s += b["Очередь"]
		"drunk":
			s -= b["Запахи"]
		"cheater":
			if has(t, "cameras"):
				s -= 8.0
			if has(t, "guards"):
				s -= 10.0
			if has(t, "detective"):
				s -= 6.0
	return s


func price(t: int, role: String, kind: String, id: String = "") -> int:
	var c := 0.0
	var lvl: int = teams[t].level
	match kind:
		"build":
			c = Defs.fac_by_id[id].cost
		"defense":
			c = Defs.def_by_id[id].cost
		"upgrade":
			if lvl >= Defs.MAX_LEVEL:
				return 0
			c = Defs.LEVEL_COST[lvl + 1]
		"ability":
			var a: Dictionary = Defs.abil_by_id[id]
			c = a.base + a.per_lvl * lvl
		"sabotage":
			var s: Dictionary = Defs.sab_by_id[id]
			c = s.cost
			if role == "saboteur":
				c *= 0.85
			if teams[t].revenge > 0 and not s.get("self", false):
				c *= 0.5
			return int(c)
	if role == "director":
		c *= 0.9
	return int(c)


## Пустая строка — можно. Иначе причина, почему нельзя.
func can(t: int, role: String, kind: String, id: String = "") -> String:
	if teams.size() != 2:
		return "Нет матча"
	var st: Dictionary = teams[t]
	var lvl: int = st.level
	var cost := price(t, role, kind, id)
	match kind:
		"build":
			var f: Dictionary = Defs.fac_by_id[id]
			if st.built.has(id):
				return "Построено"
			if lvl < f.lvl:
				return "Нужен ур. %d" % f.lvl
		"defense":
			var d: Dictionary = Defs.def_by_id[id]
			if st.defense.has(id):
				return "Нанят"
			if lvl < d.lvl:
				return "Нужен ур. %d" % d.lvl
		"upgrade":
			if lvl >= Defs.MAX_LEVEL:
				return "Максимум"
			if not _tier_done(t):
				return "Постройте объект ур. %d" % lvl
		"ability":
			var a: Dictionary = Defs.abil_by_id[id]
			if lvl < a.lvl:
				return "Нужен ур. %d" % a.lvl
			if st.cd.has(id):
				return "Ждать %d с" % ceili(st.cd[id])
		"sabotage":
			var s: Dictionary = Defs.sab_by_id[id]
			if lvl < s.lvl:
				return "Нужен ур. %d" % s.lvl
			if st.cd.has(id):
				return "Ждать %d с" % ceili(st.cd[id])
			if s.dur > 0 and not s.get("self", false) and has_eff(1 - t, id):
				return "Уже действует"
		_:
			return "?"
	if st.money < cost:
		return "Мало денег"
	return ""


func _tier_done(t: int) -> bool:
	var lvl: int = teams[t].level
	for f in Defs.FACILITIES:
		if f.lvl == lvl and teams[t].built.has(f.id):
			return true
	return false


func score(t: int) -> int:
	var st: Dictionary = teams[t]
	return int(st.money + float(st.get("till", 0.0)) + st.stats.invested * 0.6 + st.rep * 300.0)


# =============================================================================
# Действия игроков
# =============================================================================
func request(action: Dictionary) -> void:
	if not running:
		return
	if authority:
		_handle(multiplayer.get_unique_id(), action)
	else:
		_rpc_action.rpc_id(1, action)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_action(action: Dictionary) -> void:
	if authority and running:
		_handle(multiplayer.get_remote_sender_id(), action)


func _handle(peer_id: int, action: Dictionary) -> void:
	var pl: Dictionary = Net.players.get(peer_id, {})
	if pl.is_empty():
		return
	var err := do_action(int(pl.team), String(pl.role), action, String(pl.name))
	if err != "":
		_toast_peer(peer_id, err, "bad")


func do_action(t: int, role: String, a: Dictionary, who := "") -> String:
	var kind := String(a.get("a", ""))
	var id := String(a.get("id", ""))
	if kind == "surrender":
		_end(1 - t, "«%s» сдался и ушёл торговать шаурмой." % teams[t].name)
		return ""
	var err := can(t, role, kind, id)
	if err != "":
		return err
	var st: Dictionary = teams[t]
	var cost := price(t, role, kind, id)
	st.money -= cost
	var by := (" (%s)" % who) if who != "" and Net.online else ""
	match kind:
		"build":
			st.built[id] = true
			st.stats.invested += cost
			_ev("«%s» построил: %s%s" % [st.name, Defs.fac_by_id[id].name, by], "build", t)
			_fx(t, "build:" + id)
		"defense":
			st.defense[id] = true
			st.stats.invested += cost
			_ev("«%s» нанял: %s%s" % [st.name, Defs.def_by_id[id].name, by], "build", t)
			_fx(t, "build:" + id)
		"upgrade":
			st.level += 1
			st.stats.invested += cost
			_ev("«%s» вырос до уровня %d!%s" % [st.name, st.level, by], "big", t)
			_fx(t, "levelup")
			if st.level == Defs.MAX_LEVEL:
				_ev("«%s» достиг 10 уровня! Открыты Тотальные Саботажи. Соседям стоит нервничать." % st.name, "big", t)
		"ability":
			_ability(t, id)
		"sabotage":
			_sabotage(t, role, id, cost)
	_appeal_cache[t] = _calc_breakdown(t)
	_send_state()
	return ""


func _ability(t: int, id: String) -> void:
	var st: Dictionary = teams[t]
	var a: Dictionary = Defs.abil_by_id[id]
	st.cd[id] = float(a.cd)
	match id:
		"cleanup":
			var n := 0
			for e in PHYSICAL:
				if st.effects.erase(e):
					n += 1
			_ev("«%s» устроил экстренную уборку%s." % [st.name, "" if n > 0 else " (на всякий случай)"], "good", t)
			_fx(t, "cleanup")
		"party":
			st.buffs["party"] = float(a.dur)
			_ev("«%s» раздаёт бесплатные коктейли! Толпа уже бежит." % st.name, "good", t)
			_fx(t, "party")
		"pr_campaign":
			st.rep = minf(100.0, st.rep + 8.0)
			st.effects.erase("rumor")
			st.effects.erase("news")
			_ev("«%s» провёл PR-кампанию: «Мы — честное казино!» Публика почти поверила." % st.name, "good", t)
			_fx(t, "pr")


func _sabotage(t: int, role: String, id: String, cost: int) -> void:
	var s: Dictionary = Defs.sab_by_id[id]
	var st: Dictionary = teams[t]
	var e := 1 - t
	var en: Dictionary = teams[e]
	st.cd[id] = float(s.cd)
	if s.get("self", false):
		st.buffs[id] = float(s.dur)
		st.stats.sab_ok += 1
		_ev("«%s» объявил БОЛЬШОЙ РОЗЫГРЫШ! Вся улица бежит к нему." % st.name, "big", t)
		_fx(t, "grand_raffle")
		return
	var revenge: bool = st.revenge > 0
	if revenge:
		st.revenge -= 1
	var chance := float(s.catch)
	for d in Defs.DEFENSES:
		if en.defense.has(d.id):
			chance += float(d.get("catch", 0.0))
	if role == "saboteur":
		chance -= 0.07
	chance = clampf(chance, 0.03, 0.85)
	if revenge:
		chance = 0.0
	if randf() < chance:
		var loss: float = (5.0 + s.tier * 3.0) * (0.6 if has(t, "lawyer") else 1.0)
		var fine := cost * (0.25 if has(t, "lawyer") else 0.5)
		st.rep = maxf(0.0, st.rep - loss)
		st.money -= fine
		st.stats.sab_caught += 1
		en.stats.caught_enemy += 1
		en.revenge = mini(3, int(en.revenge) + 1)
		_ev("ПОЙМАН! «%s» пытался устроить «%s» у «%s». Штраф %s, репутация −%d. У «%s» право на ответный удар!" % [
			st.name, s.name, en.name, Defs.money(fine), int(loss), en.name], "caught", e)
		_fx(t, "caught")
		_popup(t, "ПОЙМАН!", "bad")
		return
	st.stats.sab_ok += 1
	_attacked[e] = 30.0
	var mult := 1.0
	match id:
		"roaches", "stink", "plumbing":
			if has(e, "cleaner"):
				mult = 0.5
		"rumor", "news":
			if has(e, "pr"):
				mult = 0.5
		"dealer_bribe", "exodus":
			if has(e, "detective"):
				mult = 0.5
	if s.dur > 0:
		en.effects[id] = float(s.dur) * mult
	var lawyer_k := 0.6 if has(e, "lawyer") else 1.0
	match id:
		"taxi":
			st.buffs["taxi"] = float(s.dur)
			en.effects.erase("taxi")
			_ev("Таксисты района внезапно полюбили «%s». Совпадение?" % st.name, "sabotage", t)
		"brawlers":
			for i in 3:
				var p := _spawn_ped_at("brawler", Vector2(randf_range(-3, 3) + i, sgn(t) * PLAZA_Z), e)
				p.speed *= randf_range(0.9, 1.1)
			_ev("Трое крикливых мужиков направились к «%s»..." % en.name, "sabotage", t)
		"news":
			en.rep = maxf(0.0, en.rep - 15.0 * lawyer_k * mult)
			_ev("СРОЧНО: «%s» в центре скандала! Журналисты уже у входа." % en.name, "sabotage", t)
		"dealer_bribe":
			var steal := maxf(0.0, en.money) * 0.08 * mult
			en.money -= steal
			st.money += steal * 0.5
			_ev("Крупье «%s» весь вечер «случайно» проигрывают. Утекло %s." % [en.name, Defs.money(steal)], "sabotage", t)
		"exodus":
			var n := 0
			for p: Ped in peds.values():
				if p.target == e and p.state in [INSIDE, QUEUE]:
					_exit_ped(p, 0.0, t if randf() < 0.5 else -1)
					n += 1
			_ev("ПОЖАРНАЯ ТРЕВОГА в «%s»! (ложная) Выбежало %d клиентов." % [en.name, n], "sabotage", t)
		"black_monday":
			en.rep = maxf(0.0, en.rep - 10.0 * lawyer_k)
			_ev("Над «%s» сгустились тучи. Наступил ЧЁРНЫЙ ПОНЕДЕЛЬНИК." % en.name, "sabotage", t)
		"sign_war":
			st.buffs["sign_war_own"] = float(s.dur)
			_ev("ВОЙНА ВЫВЕСОК! Вывеска «%s» выросла втрое, у «%s» — погасла." % [st.name, en.name], "sabotage", t)
		"road_op":
			_ev("Операция «Дорога»: перед «%s» внезапно начался ремонт. Пройти невозможно." % en.name, "sabotage", t)
		_:
			var msgs := {
				"roaches": "В «%s» завелись тараканы. Совпадение? Не думаем.",
				"stink": "Из вентиляции «%s» несёт тухлой рыбой.",
				"music_break": "В «%s» играет шансон задом наперёд. Клиенты в шоке.",
				"rumor": "По району ползут слухи про «%s». Говорят, там автоматы на батарейках.",
				"plumbing": "В «%s» потоп! Туалет бьёт фонтаном, лифт застрял.",
				"fakemoney": "Кассы «%s» забиты фальшивками.",
			}
			_ev(String(msgs.get(id, "У «%s» неприятности.")) % en.name, "sabotage", t)
	if has(e, "detective"):
		st.rep = maxf(0.0, st.rep - 2.0)
		_ev("Детектив «%s» нашёл улики: это «%s»! Репутация пакостника −2." % [en.name, st.name], "info", e)
	_fx(e, "hit:" + id)
	_appeal_cache[e] = _calc_breakdown(e)


# =============================================================================
# Экономика
# =============================================================================
func _eco(dt: float) -> void:
	for t in 2:
		var st: Dictionary = teams[t]
		var upkeep := 0.0
		for id in st.defense:
			upkeep += float(Defs.def_by_id[id].upkeep)
		st.money -= upkeep / 60.0 * dt
		var passive: float = (fac_sum(t, "passive") + st.level * 2.0) * dt * (0.3 if has_eff(t, "black_monday") else 1.0)
		_earn(t, passive)
		var regen := fac_sum(t, "regen") + (0.03 if has(t, "pr") else 0.0)
		# Репутация медленно возвращается к 50: слухи забываются, слава приедается.
		st.rep = clampf(st.rep + regen * dt + (50.0 - st.rep) * 0.005 * dt, 0.0, 100.0)
		if has_eff(t, "roaches"):
			st.rep = maxf(0.0, st.rep - 0.05 * dt)
		for key in ["effects", "buffs", "cd"]:
			var d: Dictionary = st[key]
			for k in d.keys():
				d[k] -= dt
				if d[k] <= 0.0:
					d.erase(k)
					if key == "effects" and Defs.sab_by_id.has(k):
						_ev("У «%s» закончилось: %s." % [st.name, Defs.sab_by_id[k].name], "info", t)
		_attacked[t] = maxf(0.0, _attacked[t] - dt)
		st.queue = queues[t].size()
		st.cap = capacity(t)
		st.till_cap = till_cap_for(st.level)
		_appeal_cache[t] = _calc_breakdown(t)
		st.breakdown = _appeal_cache[t]
		st.appeal = appeal(t, "normal")
		if not demo:
			if st.money < -2000.0:
				_bankrupt[t] += dt
				if not st.warn_bankrupt:
					st.warn_bankrupt = true
					_ev("«%s» в долгах! Если не выбраться из минуса за 45 секунд — банкротство." % st.name, "caught", 1 - t)
				if _bankrupt[t] > 45.0:
					_end(1 - t, "«%s» обанкротился. Здание продано под шиномонтаж." % st.name)
					return
			else:
				_bankrupt[t] = 0.0
				st.warn_bankrupt = false
	_income_t += dt
	if _income_t >= 5.0:
		for t in 2:
			var per_min: float = _income_acc[t] / _income_t * 60.0
			teams[t].income = lerpf(teams[t].income, per_min, 0.5)
			_income_acc[t] = 0.0
		_income_t = 0.0
	_pop_t += dt
	if _pop_t >= 1.5:
		_pop_t = 0.0
		for t in 2:
			if _pop_acc[t] >= 1.0:
				_popup(t, "+" + Defs.money(_pop_acc[t]), "money")
			elif _pop_acc[t] <= -1.0:
				_popup(t, Defs.money(_pop_acc[t]), "bad")
			_pop_acc[t] = 0.0


## till=true — выручка зала: часть уходит в кассу (её забирают руками или инкассатором),
## а при полной кассе эта часть сгорает.
func _earn(t: int, amount: float, till := false) -> void:
	var st: Dictionary = teams[t]
	var to_money := amount
	if till and amount > 0.0:
		var part := amount * TILL_SHARE
		to_money -= part
		st.till = minf(float(st.till) + part, float(st.till_cap))
	st.money += to_money
	_income_acc[t] += amount
	_pop_acc[t] += amount
	if amount > 0.0:
		st.stats.earned += amount


func _end_by_time() -> void:
	var s0 := score(0)
	var s1 := score(1)
	var w := 0 if s0 > s1 else 1
	if s0 == s1:
		w = -1
	_end(w, "Время вышло. Победила империя побольше.")


func _end(winner: int, reason: String) -> void:
	if not running:
		return
	running = false
	var r := {"winner": winner, "reason": reason, "scores": [score(0), score(1)],
		"stats": [teams[0].stats, teams[1].stats], "levels": [teams[0].level, teams[1].level],
		"rep": [teams[0].rep, teams[1].rep], "money": [teams[0].money, teams[1].money]}
	_send_state()
	if networked:
		_rpc_over.rpc(r)
	else:
		_rpc_over(r)


@rpc("authority", "call_local", "reliable")
func _rpc_over(r: Dictionary) -> void:
	running = false
	result = r
	match_over.emit(r)


# =============================================================================
# Пешеходы
# =============================================================================
func _rand_type() -> String:
	var lvl: float = (teams[0].level + teams[1].level) * 0.5
	var total := 0.0
	var w := {}
	for k in Defs.CLIENTS:
		var v := float(Defs.CLIENTS[k].w)
		if k == "vip":
			v += lvl * 1.4
		w[k] = v
		total += v
	var r := randf() * total
	for k in w:
		r -= w[k]
		if r <= 0.0:
			return k
	return "normal"


func _new_ped(type: String, pos: Vector2) -> Ped:
	var p := Ped.new()
	p.id = _next_id
	_next_id += 1
	p.type = type
	p.seed = randi() % 100000
	p.pos = pos
	p.speed = float(Defs.CLIENTS[type].speed) * randf_range(0.85, 1.15)
	p.side = 0 if pos.y < 0.0 else 1
	peds[p.id] = p
	return p


func _spawn_random_ped(x := INF) -> void:
	if peds.size() >= MAX_PEDS:
		return
	var dir := 1 if randf() < 0.5 else -1
	var side := randi() % 2
	var px := -dir * END_X + dir * randf_range(0, 3) if x == INF else x
	var p := _new_ped(_rand_type(), Vector2(px, 0))
	p.dir = dir
	p.side = side
	p.lane = (-0.45 if dir > 0 else 0.45) * sgn(side) + randf_range(-0.3, 0.3)
	p.pos.y = sgn(side) * WALK_Z + p.lane
	p.state = WALK
	for t in 2:
		if has_buff(t, "grand_raffle") and randf() < 0.7:
			p.tag = "raffle"
			_route(p, t)
			_say(p, "raffle", 0.5)
			return
	if absf(px) < 26.0:
		p.decided = randf() < 0.6


func _spawn_ped_at(type: String, pos: Vector2, target: int) -> Ped:
	var p := _new_ped(type, pos)
	p.dir = 1 if randf() < 0.5 else -1
	_route(p, target)
	return p


func _route(p: Ped, t: int) -> void:
	p.decided = true
	p.target = t
	p.state = GOING
	p.path.clear()
	var my_side := 0 if p.pos.y < 0.0 else 1
	if absf(p.pos.y) > WALK_Z + 1.4:
		p.path.append(Vector2(p.pos.x * 0.5 + randf_range(-0.5, 0.5), sgn(my_side) * PLAZA_Z))
		p.path.append(Vector2(p.pos.x * 0.5 + randf_range(-2, 2), sgn(my_side) * WALK_Z))
	if my_side != t:
		var cx: float
		if p.type == "drunk" or p.type == "brawler":
			cx = p.pos.x + p.dir * randf_range(1.0, 4.0)
		else:
			cx = CROSS_X[0] if absf(p.pos.x - CROSS_X[0]) < absf(p.pos.x - CROSS_X[1]) else CROSS_X[1]
			cx += randf_range(-1.2, 1.2)
		p.path.append(Vector2(cx, sgn(my_side) * WALK_Z + randf_range(-0.4, 0.4)))
		p.path.append(Vector2(cx, sgn(t) * WALK_Z + randf_range(-0.4, 0.4)))
	p.path.append(Vector2(randf_range(-0.7, 0.7), sgn(t) * WALK_Z))
	p.path.append(Vector2(randf_range(-0.4, 0.4), sgn(t) * PLAZA_Z))
	p.path.append(Vector2(randf_range(-0.3, 0.3), sgn(t) * (DOOR_Z - 1.6)))


func _choose(p: Ped) -> int:
	# Любопытные прохожие заходят куда попало — так отстающий не остаётся совсем без клиентов.
	if randf() < 0.22:
		var opts := []
		for t in 2:
			if not has_eff(t, "road_op"):
				opts.append(t)
		if not opts.is_empty() and randf() < 0.6:
			return opts[randi() % opts.size()]
	var w_none := pow(WALK_BY, POW)
	var ws := [0.0, 0.0]
	var total := w_none
	for t in 2:
		if has_eff(t, "road_op"):
			continue
		ws[t] = pow(maxf(appeal(t, p.type), 3.0), POW)
		total += ws[t]
	var r := randf() * total
	if r < ws[0]:
		return 0
	if r < ws[0] + ws[1]:
		return 1
	return -1


func _update_spawns(dt: float) -> void:
	var rate: float = 0.8 + 0.08 * (teams[0].level + teams[1].level)
	if has_buff(0, "grand_raffle") or has_buff(1, "grand_raffle"):
		rate *= 2.0
	_spawn_acc += rate * dt
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		_spawn_random_ped()


func _move_to(p: Ped, target: Vector2, dt: float) -> bool:
	var d := target - p.pos
	var l := d.length()
	var step := p.speed * dt
	if l <= step or l < 0.05:
		p.pos = target
		return true
	p.pos += d / l * step
	p.yaw = atan2(d.x, d.y)
	p.moving = true
	return false


func _update_peds(dt: float) -> void:
	var gone := []
	for p: Ped in peds.values():
		p.moving = false
		match p.state:
			WALK:
				var tz: float = sgn(p.side) * WALK_Z + p.lane
				p.pos.y = move_toward(p.pos.y, tz, dt * 1.5)
				p.pos.x += p.dir * p.speed * dt
				p.yaw = atan2(float(p.dir), 0.0)
				p.moving = true
				if not p.decided and absf(p.pos.x) < 26.0:
					p.decided = true
					var t := _choose(p)
					if t >= 0:
						_route(p, t)
						if p.type == "drunk":
							_say(p, "drunk", 0.15)
						elif p.type == "vip":
							_say(p, "vip", 0.15)
					else:
						_gossip(p)
				if absf(p.pos.x) > END_X + 2.0:
					gone.append(p.id)
			GOING, LEAVE:
				if p.state == GOING and has_eff(p.target, "road_op") and absf(p.pos.y) < PLAZA_Z + 0.5 and p.type != "brawler":
					_say(p, "road_op", 0.4)
					_to_street(p)
					continue
				if p.path.is_empty():
					if p.state == GOING:
						_arrive(p)
					else:
						p.state = WALK
						p.side = 0 if p.pos.y < 0.0 else 1
						p.lane = (-0.45 if p.dir > 0 else 0.45) * sgn(p.side) + randf_range(-0.3, 0.3)
				elif _move_to(p, p.path[0], dt):
					p.path.pop_front()
			QUEUE:
				var i: int = queues[p.target].find(p.id)
				if i >= 0:
					var spot := queue_spot(p.target, i)
					if _move_to(p, spot, dt):
						p.yaw = PI if p.target == 0 else 0.0
				p.patience -= dt
				if p.patience <= 0.0:
					queues[p.target].erase(p.id)
					teams[p.target].rep = maxf(0.0, teams[p.target].rep - 0.3)
					_say(p, "queue", 0.6)
					_to_street(p)
			INSIDE:
				_earn(p.target, p.spend_rate * dt, true)
				p.timer -= dt
				if p.timer <= 0.0:
					_exit_ped(p, _satisfaction(p.target, p.type))
	for id in gone:
		peds.erase(id)


func _to_street(p: Ped) -> void:
	p.state = LEAVE
	p.decided = true
	p.path.clear()
	var s := 0 if p.pos.y < 0.0 else 1
	if absf(p.pos.y) > WALK_Z + 1.0:
		p.path.append(Vector2(p.pos.x + randf_range(-0.6, 0.6), sgn(s) * PLAZA_Z))
	p.path.append(Vector2(p.pos.x + randf_range(-2.5, 2.5), sgn(s) * WALK_Z))


func _arrive(p: Ped) -> void:
	var t := p.target
	var st: Dictionary = teams[t]
	if p.type == "brawler":
		_brawl(p)
		return
	if p.type == "cheater":
		var c := 0.0
		if has(t, "cameras"):
			c += 0.3
		if has(t, "guards"):
			c += 0.4
		if has(t, "detective"):
			c += 0.2
		if randf() < c:
			_say(p, "cheater_caught", 1.0)
			st.rep = minf(100.0, st.rep + 0.5)
			_popup(t, "Шулер пойман!", "good")
			_to_street(p)
			p.speed *= 1.6
			return
	if queues[t].is_empty() and st.inside < capacity(t):
		_enter(p)
	elif queues[t].size() < 10:
		queues[t].append(p.id)
		p.state = QUEUE
		p.patience = 9.0 if p.type == "vip" else randf_range(18.0, 28.0)
	else:
		st.rep = maxf(0.0, st.rep - 0.2)
		_say(p, "queue", 0.5)
		_to_street(p)


func _enter(p: Ped) -> void:
	var t := p.target
	var c: Dictionary = Defs.CLIENTS[p.type]
	p.state = INSIDE
	p.pos = door_pos(t)
	teams[t].inside += 1
	teams[t].stats.clients += 1
	p.timer = float(c.stay) * (1.0 + fac_sum(t, "stay")) * randf_range(0.8, 1.2)
	var total: float
	if p.type == "cheater":
		total = float(c.spend) * (1.0 + teams[t].level * 0.35)
	else:
		total = float(c.spend) * spend_mult(t) * randf_range(0.7, 1.3)
	p.spend_rate = total / p.timer
	if p.tag == "taxi" and has_buff(t, "taxi"):
		_say(p, "taxi", 0.5)
	elif p.tag == "raffle":
		pass
	else:
		_say(p, "enter", 0.12)


func _satisfaction(t: int, type: String) -> float:
	var s := 0.55 + fac_sum(t, "comfort") / 60.0
	if has_eff(t, "roaches"):
		s -= 0.25 if type == "family" else 0.15
	if has_eff(t, "stink") and type != "drunk":
		s -= 0.2
	if has_eff(t, "music_break"):
		s -= 0.1
	if has_eff(t, "plumbing"):
		s -= 0.2
	if has_eff(t, "black_monday"):
		s -= 0.15
	if type == "vip":
		s += 0.2 if has(t, "vip") else -0.15
	if type == "family" and has(t, "restaurant"):
		s += 0.1
	if type == "drunk" and has(t, "bar"):
		s += 0.1
	return s


func _exit_ped(p: Ped, sat: float, next_target := -1) -> void:
	var t := p.target
	if p.state == INSIDE:
		teams[t].inside = maxi(0, teams[t].inside - 1)
	elif p.state == QUEUE:
		queues[t].erase(p.id)
	var st: Dictionary = teams[t]
	if p.type != "cheater":
		var d := (sat - 0.5) * 0.35
		if d < 0.0 and has(t, "lawyer"):
			d *= 0.6
		st.rep = clampf(st.rep + d, 0.0, 100.0)
	if p.type == "drunk" and not has(t, "guards") and randf() < 0.12:
		st.rep = maxf(0.0, st.rep - 1.0)
		var jokes := ["Пьяный клиент «%s» уснул в фонтане.", "Пьяный клиент «%s» пытался поставить на кон охранника.",
			"Пьяный клиент «%s» пел гимн на крыше машины."]
		_ev(jokes[randi() % jokes.size()] % st.name, "info", 1 - t)
	p.pos = door_pos(t) + Vector2(randf_range(-0.8, 0.8), -sgn(t) * 0.6)
	if next_target >= 0:
		_say(p, "exodus", 0.6)
		p.dir = 1 if randf() < 0.5 else -1
		_route(p, next_target)
		p.speed *= 1.4
		return
	if sat <= 0.01:
		_say(p, "exodus", 0.5)
		p.speed *= 1.5
	elif sat >= 0.6:
		_say(p, "leave_happy", 0.18)
	elif sat < 0.4:
		_say(p, "leave_sad", 0.3)
	p.dir = 1 if randf() < 0.5 else -1
	p.target = t
	_to_street(p)


func _brawl(p: Ped) -> void:
	var t := p.target
	var st: Dictionary = teams[t]
	if has(t, "guards") and randf() < 0.75:
		_say(p, "brawl_caught", 1.0)
		st.rep = minf(100.0, st.rep + 1.0)
		_popup(t, "Охрана скрутила!", "good")
		_ev("Охрана «%s» скрутила скандалиста. Красиво." % st.name, "good", t)
	else:
		_say(p, "brawl", 1.0)
		var loss := 3.0 * (0.6 if has(t, "lawyer") else 1.0)
		st.rep = maxf(0.0, st.rep - loss)
		for id in queues[t].duplicate():
			var q: Ped = peds.get(id)
			if q:
				queues[t].erase(id)
				_to_street(q)
				if randf() < 0.4:
					_say(q, "exodus", 1.0)
		_popup(t, "СКАНДАЛ!", "bad")
		_fx(t, "brawl")
		_ev("Скандалист устроил сцену у входа в «%s». Очередь разбежалась." % st.name, "sabotage", 1 - t)
	p.speed *= 1.3
	_to_street(p)


func _gossip(p: Ped) -> void:
	for t in [randi() % 2]:
		for e in ["roaches", "stink", "music_break", "rumor", "news", "plumbing", "black_monday"]:
			if has_eff(t, e):
				_say(p, e, 0.35)
				return


func _update_queues() -> void:
	for t in 2:
		var q: Array = queues[t]
		while not q.is_empty() and teams[t].inside < capacity(t):
			var p: Ped = peds.get(q[0])
			q.pop_front()
			if p:
				_enter(p)


# =============================================================================
# Машины и такси
# =============================================================================
func _update_cars(dt: float) -> void:
	_car_t -= dt
	if _car_t <= 0.0:
		_car_t = randf_range(1.4, 3.2)
		_spawn_car(-1)
	_taxi_t -= dt
	if _taxi_t <= 0.0:
		var bribed := -1
		for t in 2:
			if has_buff(t, "taxi"):
				bribed = t
		_taxi_t = randf_range(3.0, 5.0) if bribed >= 0 else randf_range(7.0, 11.0)
		var target := bribed
		if target < 0:
			var p := Ped.new()
			p.type = "normal"
			target = _choose(p)
			if target < 0:
				target = randi() % 2
		if not has_eff(target, "road_op"):
			_spawn_car(target)
	var gone := []
	for c: Car in cars.values():
		var desired := c.speed
		if c.drop_target >= 0 and not c.dropped:
			var dist := (c.stop_x - c.x) * c.dir
			if dist < 10.0:
				desired = clampf(dist * 1.2, 0.0, c.speed)
			if dist < 0.3:
				desired = 0.0
				c.stop_t += dt
				if c.stop_t > 0.6:
					c.dropped = true
					var p := _new_ped(_rand_type_taxi(), Vector2(c.x, sgn(c.drop_target) * 4.4))
					p.dir = c.dir
					p.tag = "taxi"
					_route(p, c.drop_target)
		elif c.dropped and c.stop_t < 1.6:
			c.stop_t += dt
			desired = 0.0
		for p: Ped in peds.values():
			if absf(p.pos.y) < 4.3 and absf(p.pos.y - c.z) < 2.8:
				var ahead: float = (p.pos.x - c.x) * c.dir
				if ahead > 1.0 and ahead < 7.5:
					desired = 0.0
					break
		for o: Car in cars.values():
			if o != c and o.dir == c.dir:
				var gap: float = (o.x - c.x) * c.dir
				if gap > 0.0 and gap < 7.0:
					desired = minf(desired, o.cur * 0.8 if gap > 5.0 else 0.0)
		c.cur = move_toward(c.cur, desired, (14.0 if desired < c.cur else 6.0) * dt)
		c.x += c.dir * c.cur * dt
		if absf(c.x) > 88.0:
			gone.append(c.id)
	for id in gone:
		cars.erase(id)


func _rand_type_taxi() -> String:
	var t := _rand_type()
	return "vip" if t == "cheater" and randf() < 0.5 else t


func _spawn_car(drop_target: int) -> void:
	if cars.size() > 18:
		return
	var c := Car.new()
	c.id = _next_id
	_next_id += 1
	c.dir = 1 if randf() < 0.5 else -1
	if drop_target >= 0:
		c.dir = 1 if drop_target == 0 else -1
		c.sub = 10
		c.drop_target = drop_target
		c.stop_x = -3.0 * c.dir + randf_range(-1, 1)
	else:
		c.sub = 10 if randf() < 0.2 else randi() % 6
	c.z = -2.0 if c.dir > 0 else 2.0
	c.x = -c.dir * 86.0
	c.speed = randf_range(8.0, 12.0)
	c.cur = c.speed
	cars[c.id] = c


# =============================================================================
# ИИ
# =============================================================================
func _ai(t: int, dt: float) -> void:
	_ai_t[t] -= dt
	if _ai_t[t] > 0.0:
		return
	var diff := int(Net.settings.get("ai", 1)) if not demo else 1
	_ai_t[t] = [4.5, 2.6, 1.5][diff] * randf_range(0.7, 1.3)
	var st: Dictionary = teams[t]
	var R := "boss"
	var bad := 0
	for e in PHYSICAL:
		if has_eff(t, e):
			bad += 1
	# Уборка и PR — только если это не съедает накопления на развитие.
	var next_cost := price(t, R, "upgrade")
	var spare := func(kind: String, id: String) -> bool: return st.money - price(t, R, kind, id) > next_cost * 0.5
	if (bad >= 2 or (bad == 1 and spare.call("ability", "cleanup"))) and randf() < [0.3, 0.6, 0.95][diff] and _ai_try(t, "ability", "cleanup"):
		return
	if (st.rep < 35.0 or has_eff(t, "news")) and spare.call("ability", "pr_campaign") and _ai_try(t, "ability", "pr_campaign"):
		return
	if _ai_try(t, "upgrade"):
		return
	# Цель накопления — следующий уровень или самое дешёвое здание текущего уровня.
	var goal := 0
	if st.level < Defs.MAX_LEVEL:
		goal = price(t, R, "upgrade")
		if not _tier_done(t):
			goal = 999999
			for f in Defs.FACILITIES:
				if f.lvl == st.level:
					goal = mini(goal, int(f.cost))
	var builds := []
	for f in Defs.FACILITIES:
		if can(t, R, "build", f.id) == "" and (f.lvl == st.level or st.money - f.cost > goal * 0.6):
			builds.append(f)
	if not builds.is_empty():
		builds.sort_custom(func(a, b): return a.lvl > b.lvl)
		if do_action(t, R, {"a": "build", "id": builds[0].id}) == "":
			return
	var threat: bool = _attacked[t] > 0.0 or teams[1 - t].stats.sab_ok > st.stats.caught_enemy + 2
	for d in Defs.DEFENSES:
		if can(t, R, "defense", d.id) == "" and (threat or st.level >= d.lvl + 1) and st.money > d.cost * 1.2 + goal * 0.4:
			if do_action(t, R, {"a": "defense", "id": d.id}) == "":
				return
	var aggro: float = [0.12, 0.22, 0.32][diff]
	var reserve: float = [1.0, 0.7, 0.5][diff]
	if teams[1 - t].effects.size() >= 2:
		aggro *= 0.3
	if st.revenge > 0:
		aggro = 1.0
		reserve = 0.2
	if randf() < aggro and (elapsed - float(st.get("ai_last_sab", -999.0)) > [35.0, 20.0, 12.0][diff] or st.revenge > 0):
		# Бюджет на пакости — доля от заработанного, чтобы ИИ не проедал накопления на развитие.
		var budget: float = st.stats.earned * [0.08, 0.14, 0.2][diff] - float(st.get("ai_sab_spent", 0.0))
		var opts := []
		for s in Defs.SABOTAGES:
			var sc := price(t, R, "sabotage", s.id)
			if can(t, R, "sabotage", s.id) == "" and st.money - sc > goal * reserve and (sc <= budget or st.revenge > 0):
				opts.append(s)
		if not opts.is_empty():
			opts.sort_custom(func(a, b): return a.cost > b.cost)
			var pick: Dictionary = opts[randi() % mini(3, opts.size())]
			st["ai_sab_spent"] = float(st.get("ai_sab_spent", 0.0)) + price(t, R, "sabotage", pick.id)
			st["ai_last_sab"] = elapsed
			do_action(t, R, {"a": "sabotage", "id": pick.id})
			return
	if randf() < 0.15 and st.money > goal + 1500:
		_ai_try(t, "ability", "party")


func _ai_try(t: int, kind: String, id := "") -> bool:
	if can(t, "boss", kind, id) != "":
		return false
	return do_action(t, "boss", {"a": kind, "id": id}) == ""


# =============================================================================
# Синхронизация и события
# =============================================================================
const ENT_BYTES := 12
const ENTS_PER_PACKET := 96  # 96 * 12 = 1152 байт — меньше MTU, пакеты через VPN не дробятся


## Снимок сущностей: 12 байт на штуку, порциями меньше MTU.
func _send_ents() -> void:
	var buf := PackedByteArray()
	var n := 0
	var all: Array = []
	for p: Ped in peds.values():
		if p.state != INSIDE:
			all.append(p)
	for c: Car in cars.values():
		all.append(c)
	buf.resize(mini(all.size(), ENTS_PER_PACKET) * ENT_BYTES)
	for e in all:
		var o := n * ENT_BYTES
		if e is Ped:
			buf.encode_u16(o, e.id & 0xFFFF)
			buf.encode_u8(o + 2, Defs.CLIENT_TYPES.find(e.type))
			buf.encode_u8(o + 3, 1 if e.moving else 0)
			buf.encode_u16(o + 4, e.seed & 0xFFFF)
			buf.encode_s16(o + 6, int(clampf(e.pos.x, -320, 320) * 100.0))
			buf.encode_s16(o + 8, int(clampf(e.pos.y, -320, 320) * 100.0))
			buf.encode_u8(o + 10, int(wrapf(e.yaw, 0.0, TAU) / TAU * 255.0))
			buf.encode_u8(o + 11, 0)
		else:
			buf.encode_u16(o, e.id & 0xFFFF)
			buf.encode_u8(o + 2, 16 + e.sub)
			buf.encode_u8(o + 3, 0)
			buf.encode_u16(o + 4, e.id & 0xFFFF)
			buf.encode_s16(o + 6, int(clampf(e.x, -320, 320) * 100.0))
			buf.encode_s16(o + 8, int(e.z * 100.0))
			buf.encode_u8(o + 10, 64 if e.dir > 0 else 191)
			buf.encode_u8(o + 11, int(clampf(e.cur * 10.0, 0, 255)))
		n += 1
		if n == ENTS_PER_PACKET:
			_flush_ents(buf)
			buf = PackedByteArray()
			buf.resize(mini(all.size() - ENTS_PER_PACKET, ENTS_PER_PACKET) * ENT_BYTES)
			n = 0
	if n > 0:
		buf.resize(n * ENT_BYTES)
		_flush_ents(buf)


func _flush_ents(buf: PackedByteArray) -> void:
	if networked:
		_rpc_ents.rpc(buf)
	_rpc_ents(buf)


## Распаковывает в формат по 8 float на сущность: id, kind, sub, seed, x, z, yaw, moving/speed.
@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_ents(buf: PackedByteArray) -> void:
	var n := buf.size() / ENT_BYTES
	var arr := PackedFloat32Array()
	arr.resize(n * 8)
	for i in n:
		var o := i * ENT_BYTES
		var k := buf.decode_u8(o + 2)
		var car := k >= 16
		arr[i * 8] = buf.decode_u16(o)
		arr[i * 8 + 1] = 1.0 if car else 0.0
		arr[i * 8 + 2] = k - 16 if car else k
		arr[i * 8 + 3] = buf.decode_u16(o + 4)
		arr[i * 8 + 4] = buf.decode_s16(o + 6) / 100.0
		arr[i * 8 + 5] = buf.decode_s16(o + 8) / 100.0
		arr[i * 8 + 6] = buf.decode_u8(o + 10) / 255.0 * TAU
		arr[i * 8 + 7] = buf.decode_u8(o + 11) / 10.0 if car else float(buf.decode_u8(o + 3))
	last_ents = arr
	ents_updated.emit(arr)


func _send_state() -> void:
	if networked:
		_rpc_state.rpc(teams, time_left, ai_teams)
	state_updated.emit()


@rpc("authority", "call_remote", "reliable")
func _rpc_state(t: Array, tl: float, ai: Array) -> void:
	teams = t
	time_left = tl
	ai_teams = ai
	running = result.is_empty()
	for i in 2:
		_appeal_cache[i] = teams[i].get("breakdown", {})
	state_updated.emit()


func _ev(text: String, kind: String, good_team: int) -> void:
	if networked:
		_rpc_event.rpc(text, kind, good_team)
	else:
		_rpc_event(text, kind, good_team)


@rpc("authority", "call_local", "reliable")
func _rpc_event(text: String, kind: String, good_team: int) -> void:
	event_logged.emit(text, kind, good_team)


func _say(p: Ped, key: String, chance: float) -> void:
	if randf() > chance or (_bubble_cd > 0.0 and chance < 1.0):
		return
	_bubble_cd = 0.7
	var text := Defs.line(key)
	if networked:
		_rpc_bubble.rpc(p.id & 0xFFFF, text)
	else:
		_rpc_bubble(p.id & 0xFFFF, text)


@rpc("authority", "call_local", "reliable")
func _rpc_bubble(id: int, text: String) -> void:
	bubble.emit(id, text)


func _popup(t: int, text: String, kind: String) -> void:
	if networked:
		_rpc_popup.rpc(t, text, kind)
	else:
		_rpc_popup(t, text, kind)


@rpc("authority", "call_local", "reliable")
func _rpc_popup(t: int, text: String, kind: String) -> void:
	popup.emit(t, text, kind)


func _fx(t: int, name: String) -> void:
	if networked:
		_rpc_fx.rpc(t, name)
	else:
		_rpc_fx(t, name)


@rpc("authority", "call_local", "reliable")
func _rpc_fx(t: int, name: String) -> void:
	fx.emit(t, name)


func _toast_peer(peer_id: int, text: String, kind: String) -> void:
	if peer_id == multiplayer.get_unique_id() or not networked:
		toast.emit(text, kind)
	else:
		_rpc_toast.rpc_id(peer_id, text, kind)


@rpc("authority", "call_remote", "reliable")
func _rpc_toast(text: String, kind: String) -> void:
	toast.emit(text, kind)


func send_chat(text: String) -> void:
	text = text.strip_edges().left(140)
	if text == "":
		return
	if networked:
		_rpc_chat.rpc(Net.my_name, Net.my_team(), text)
	else:
		_rpc_chat(Net.my_name, Net.my_team(), text)


@rpc("any_peer", "call_local", "reliable")
func _rpc_chat(sender: String, team: int, text: String) -> void:
	chat.emit(sender.left(20), team, text.left(140))


func system_message(text: String) -> void:
	chat.emit("", -1, text)
	if networked and authority:
		_rpc_sys.rpc(text)


@rpc("authority", "call_remote", "reliable")
func _rpc_sys(text: String) -> void:
	chat.emit("", -1, text)

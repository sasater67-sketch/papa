extends Node
## Отладочные автотесты. Включается только аргументами после «--»: --dev и опции ниже.
## --solo  --aivsai  --timescale=N  --log=SEC  --shot=PATH@SEC (можно несколько)  --quit=SEC
## --host  --join=IP  --cam=own|enemy|overview  --action=kind:id@SEC  --menushot=PATH@SEC

var args := {}
var shots: Array = []
var _t := 0.0
var _log_t := 0.0
var _in_match := false
var _actions: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			var p := a.substr(7).split("@")
			shots.append([p[0], float(p[1]), p[2] if p.size() > 2 else ""])
		elif a.begins_with("--action="):
			var p := a.substr(9).split("@")
			var k := p[0].split(":")
			_actions.append([k[0], k[1] if k.size() > 1 else "", float(p[1])])
		elif a.contains("="):
			var kv := a.split("=")
			args[kv[0].trim_prefix("--")] = kv[1]
		else:
			args[a.trim_prefix("--")] = true
	if args.has("timescale"):
		Engine.time_scale = float(args.timescale)
	print("[dev] args ", args)
	if args.has("menushot"):
		var p := String(args.menushot).split("@")
		get_tree().create_timer(float(p[1]), true, false, true).timeout.connect(func(): _shot(p[0]))
	if args.has("solo"):
		get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): Net.start_solo({"duration": int(args.get("duration", 20)), "ai": int(args.get("ai", 1))}))
	elif args.has("host"):
		print("[dev] host: ", Net.host(Defs.DEFAULT_PORT))
		if args.has("mode"):
			Net.set_setting("mode", String(args.mode))
		Net.lobby_changed.connect(func():
			print("[dev] lobby players=", Net.players.size(), " ", Net.players.values())
			if Net.players.size() >= int(args.get("players", 2)) and not Net.in_match:
				get_tree().create_timer(1.0).timeout.connect(Net.start_match))
	elif args.has("join"):
		print("[dev] join: ", Net.join(String(args.join), Defs.DEFAULT_PORT))
		Net.connected_ok.connect(func(): print("[dev] connected, id=", Net.my_id()))
		Net.connection_failed.connect(func(r): print("[dev] FAIL ", r))
		Net.disconnected.connect(func(r): print("[dev] DISCONNECTED ", r))
	Game.match_over.connect(func(r): print("[dev] MATCH OVER ", r.winner, " ", r.reason, " scores=", r.scores))
	Game.event_logged.connect(func(t, k, g): if args.has("events"): print("[ev] ", k, " ", t))
	Game.toast.connect(func(t, k): print("[toast] ", k, " ", t))
	if args.has("uitest"):
		get_tree().create_timer(1.0).timeout.connect(_ui_test_menu)


## Прогоняет все экраны меню и лобби, затем матч: каждая карточка, пауза, помощь, чат, сдача.
func _ui_test_menu() -> void:
	var m := get_tree().current_scene
	for f in ["_show_solo", "_show_host", "_show_join", "_show_settings", "_show_help"]:
		m.call(f)
		print("[ui] menu ", f, " ok")
	print("[ui] host ", Net.host(Defs.DEFAULT_PORT + 1))
	m.call("_show_lobby")
	Net.set_setting("mode", "2v2")
	Net.set_setting("roles", true)
	Net.request_role("saboteur")
	Net.request_team(1)
	print("[ui] lobby ok players=", Net.players)
	m.call("_leave")
	await get_tree().create_timer(0.5).timeout
	Net.start_solo({"duration": 10, "ai": 2})
	await get_tree().create_timer(2.0).timeout
	var hud: Node = null
	for c in get_tree().current_scene.get_children():
		if c is CanvasLayer:
			hud = c
	Game.teams[0].money = 1e6
	for lvl in range(2, 11):
		Game.request({"a": "upgrade"})
		for f in Defs.FACILITIES:
			Game.request({"a": "build", "id": f.id})
	for d in Defs.DEFENSES:
		Game.request({"a": "defense", "id": d.id})
	for a in Defs.ABILITIES:
		Game.request({"a": "ability", "id": a.id})
	for s in Defs.SABOTAGES:
		Game.request({"a": "sabotage", "id": s.id})
	await get_tree().create_timer(1.0).timeout
	for c in hud._cards:
		c.btn.pressed.emit()
	hud._upgrade.btn.pressed.emit()
	print("[ui] cards ok level=", Game.teams[0].level, " built=", Game.teams[0].built.size(), " def=", Game.teams[0].defense.size(), " enemy effects=", Game.teams[1].effects.keys())
	hud._toggle("help")
	hud._toggle("help")
	hud._toggle("menu")
	hud._toggle("menu")
	hud._on_chat_submit("привет [b]соседям[/b]")
	for i in hud._tabs.get_tab_count():
		hud._tabs.current_tab = i
	await get_tree().create_timer(3.0).timeout
	Game.request({"a": "surrender"})
	await get_tree().create_timer(1.0).timeout
	print("[ui] end screen=", hud._end != null)
	hud._to_menu()
	await get_tree().create_timer(2.0).timeout
	print("[ui] back in ", get_tree().current_scene.name, " DONE")
	get_tree().quit()


## Сценарий режима «Хозяин»: касса, починка, пакость руками, кража, флаер, машина, нокаут.
func _fp_test(scene: Node) -> void:
	var pl: CharacterBody3D = scene.player
	var me: Dictionary = Game.teams[0]
	var en: Dictionary = Game.teams[1]
	var wait := func(s: float) -> void: await get_tree().create_timer(s).timeout
	var go := func(p: Vector3, yaw := 0.0) -> void:
		pl.teleport(p, yaw)
		Game.fp_send(pl.global_position, pl.yaw, 0)
	var events := []
	Game.fp_event.connect(func(k, d): events.append(k); print("[fp] event ", k, " ", d))
	scene.set_fp(true)
	me.money = 200000.0
	for lvl in 6:
		for f in Defs.FACILITIES:
			if f.lvl <= me.level:
				Game.request({"a": "build", "id": f.id})
		Game.request({"a": "upgrade"})
	print("[fp] level=", me.level, " built=", me.built.keys())
	await wait.call(1.0)
	# 1. касса
	me.till = 321.0
	await go.call(Game.spot_pos(0, "till") + Vector3(0, 0.3, 0.6))
	await wait.call(0.3)
	pl._update_focus()
	print("[fp] focus at till: ", pl.focus.get("prompt", "-"))
	var m0: float = me.money
	Game.request({"a": "fp", "op": "collect"})
	print("[fp] collect: till=", me.till, " money+", me.money - m0, " OK" if me.till == 0.0 and me.money - m0 > 320 else " FAIL")
	# 2. починка
	me.effects["roaches"] = 60.0
	await go.call(Game.spot_pos(0, "door") + Vector3(0, 0.3, 0.8))
	await wait.call(0.3)
	pl._update_focus()
	print("[fp] focus at own door: ", pl.focus.get("prompt", "-"))
	Game.request({"a": "fp", "op": "fix", "arg": "roaches"})
	print("[fp] fix roaches: ", "OK" if not me.effects.has("roaches") else "FAIL")
	# 3. пакость руками у соседа
	await go.call(Game.spot_pos(1, "ac") + Vector3(0, 0.3, -0.8), PI)
	await wait.call(0.3)
	pl._update_focus()
	print("[fp] focus at enemy AC: ", pl.focus.get("prompt", "-"))
	var caught0: int = me.stats.sab_caught
	Game.request({"a": "fp", "op": "plant", "arg": "ac"})
	print("[fp] plant stink: enemy stink=", en.effects.has("stink"), " caught=", me.stats.sab_caught > caught0, " OK" if en.effects.has("stink") or me.stats.sab_caught > caught0 else " FAIL")
	# 4. кража из кассы соседа
	en.till = 800.0
	await go.call(Game.spot_pos(1, "till") + Vector3(0, 0.3, -0.6), PI)
	await wait.call(0.3)
	pl._update_focus()
	print("[fp] focus at enemy till: ", pl.focus.get("prompt", "-"))
	Game.request({"a": "fp", "op": "steal"})
	print("[fp] steal: enemy till=", en.till, " stolen=", me.stats.stolen, " OK" if en.till < 800.0 or "kicked" in events else " FAIL")
	# 5. флаер прохожему
	var target = null
	for id in scene.world.ents:
		var n = scene.world.ents[id]
		if n.has_method("set_detail") and absf(n.position.z) > 4.5 and absf(n.position.z) < 7.0 and n.type != "brawler":
			target = n
			break
	if target:
		var tp: Vector3 = target.position
		await go.call(tp + Vector3(0, 0.3, 0.9 * signf(tp.z)), 0.0)
		var l0: int = me.stats.lured
		Game.request({"a": "fp", "op": "lure", "arg": int(target.get_meta("id"))})
		print("[fp] lure ped ", target.get_meta("id"), ": lured=", me.stats.lured, " OK" if me.stats.lured > l0 else " FAIL")
	# 6. машина
	var car = null
	for tries in 60:
		for c in Game.cars.values():
			if absf(c.x) < 60.0 and c.cur > 4.0:
				car = c
				break
		if car:
			break
		await wait.call(0.25)
	if car:
		await go.call(Vector3(car.x + car.dir * 1.5, 0.3, car.z))
		Game.fp_send(pl.global_position, pl.yaw, 0)
		await wait.call(0.4)
		print("[fp] car hit: ", "OK" if "car" in events else "нет удара (машина успела затормозить)")
	else:
		print("[fp] car: no moving car found, cars=", Game.cars.size())
	# 7. нокаут: подставной соперник
	Net.players[99] = {"name": "Сосед", "team": 1, "role": "boss"}
	Game._store_fp(99, pl.global_position + Vector3(0, 0, 1.0), 0.0, 0)
	for i in 3:
		Game.request({"a": "fp", "op": "punch", "peer": 99})
		await wait.call(0.45)
	print("[fp] ko: ", "OK" if Game.is_ko(99) else "FAIL")
	Net.players.erase(99)
	await go.call(Game.spawn_pos(0, 0), PI)
	print("[fp] DONE")


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	var now_match := scene != null and scene.name == "Match"
	if now_match and not _in_match:
		_in_match = true
		_t = 0.0
		print("[dev] match started; my team=", Net.my_team(), " authority=", Game.authority)
		if args.has("aivsai"):
			Game.ai_teams = [true, true]
		if args.has("fp"):
			scene.set_fp(true)
		if args.has("fpat"):
			# --fpat=x,y,z,yaw_deg,pitch_deg
			var v := String(args.fpat).split(",")
			scene.set_fp(true)
			scene.player.teleport(Vector3(float(v[0]), float(v[1]), float(v[2])), deg_to_rad(float(v[3])))
			scene.player.pitch = deg_to_rad(float(v[4])) if v.size() > 4 else 0.0
			scene.player.controls = false
		if args.has("fptest"):
			_fp_test(scene)
		if args.has("cam"):
			var cam = scene.get_child(1)
			cam.preset(String(args.cam), Net.my_team())
			cam.snap()
	if not _in_match:
		return
	_t += delta / maxf(Engine.time_scale, 0.001)
	for s in shots.duplicate():
		if s[2] != "" and _t >= s[1] - 2.0 and not s.has("cam_set"):
			s.append("cam_set")
			var parts := String(s[2]).split(",")
			var cam = scene.get_child(1)
			if parts[0] == "custom":
				cam.target = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
				cam.yaw = float(parts[4])
				cam.elev = float(parts[5])
				cam.dist = float(parts[6])
			else:
				cam.preset(parts[0], Net.my_team())
			cam.snap()
		if _t >= s[1]:
			shots.erase(s)
			_shot(s[0])
	for a in _actions.duplicate():
		if _t >= a[2]:
			_actions.erase(a)
			if a[0] == "money":
				Game.teams[Net.my_team()].money += float(a[1])
				print("[dev] +money")
			elif a[0] == "inside":
				for t in 2:
					Game.teams[t].inside = int(a[1])
				Game._send_state()
			elif a[0] == "fp":
				print("[dev] fp op ", a[1])
				Game.request({"a": "fp", "op": a[1]})
			elif a[0] == "level":
				for t in 2:
					Game.teams[t].level = int(a[1])
					for f in Defs.FACILITIES:
						if f.lvl <= int(a[1]):
							Game.teams[t].built[f.id] = true
					for d in Defs.DEFENSES:
						if d.lvl <= int(a[1]):
							Game.teams[t].defense[d.id] = true
				Game._send_state()
			elif a[0] == "effects":
				for s in Defs.SABOTAGES:
					if s.dur > 0:
						if s.get("self", false):
							Game.teams[int(a[1])].buffs[s.id] = 999.0
						else:
							Game.teams[int(a[1])].effects[s.id] = 999.0
				Game.teams[int(a[1])].buffs["party"] = 999.0
				Game._send_state()
			else:
				print("[dev] action ", a[0], " ", a[1])
				Game.request({"a": a[0], "id": a[1]})
	if args.has("log"):
		_log_t += delta
		if _log_t >= float(args.log):
			_log_t = 0.0
			var parts := []
			for t in Game.teams.size():
				var st: Dictionary = Game.teams[t]
				parts.append("T%d L%d $%d rep%d inc%d in%d/%d q%d b%d d%d sab%d/%d" % [t, st.level, int(st.money), int(st.rep), int(st.income), st.inside, st.cap, st.queue,
					st.built.size(), st.defense.size(), st.stats.sab_ok, st.stats.sab_caught])
			print("[log] t=%s peds=%d cars=%d fp=%s | %s" % [Defs.time_str(Game.elapsed if Game.authority else 0.0), Game.peds.size(), Game.cars.size(), str(Game.fp.keys()), " | ".join(parts)])
	if args.has("quit") and _t >= float(args.quit):
		print("[dev] quit")
		get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[dev] screenshot ", path, " ", img.get_size())

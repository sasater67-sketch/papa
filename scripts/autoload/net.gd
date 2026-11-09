extends Node
## Сеть и лобби. Хост — авторитетный сервер (ENet). Подходит для Radmin VPN / Hamachi / LAN.

signal lobby_changed
signal connected_ok
signal connection_failed(reason: String)
signal disconnected(reason: String)

var players := {}  # peer_id -> {name, team, role}
var settings := {"mode": "1v1", "duration": 20, "ai": 1, "roles": true, "fill_ai": true}
var my_name := "Игрок"
var online := false
var in_match := false
var _peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connect_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	var n := OS.get_environment("USERNAME")
	if n == "":
		n = OS.get_environment("USER")
	my_name = n if n != "" and n != "root" else "Игрок %d" % (randi() % 900 + 100)
	if Defs.player_name != "":
		my_name = Defs.player_name


func my_id() -> int:
	return multiplayer.get_unique_id()


func me() -> Dictionary:
	return players.get(my_id(), {"name": my_name, "team": 0, "role": "boss"})


func my_team() -> int:
	return int(me().get("team", 0))


func my_role() -> String:
	return String(me().get("role", "boss"))


func is_host() -> bool:
	return multiplayer.is_server()


func max_players() -> int:
	return 4 if settings.mode == "2v2" else 2


func per_team() -> int:
	return 2 if settings.mode == "2v2" else 1


# ---------------------------------------------------------------------------
func host(port: int) -> String:
	close()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, 8)
	if err != OK:
		_peer = null
		return "Не удалось открыть порт %d (ошибка %d). Порт занят или запрещён брандмауэром." % [port, err]
	multiplayer.multiplayer_peer = _peer
	online = true
	players = {1: {"name": my_name, "team": 0, "role": _default_role(0)}}
	lobby_changed.emit()
	return ""


func join(ip: String, port: int) -> String:
	close()
	ip = ip.strip_edges()
	if ip == "":
		return "Введите IP-адрес хоста."
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(ip, port)
	if err != OK:
		_peer = null
		return "Не удалось создать подключение (ошибка %d)." % err
	multiplayer.multiplayer_peer = _peer
	online = true
	return ""


func close() -> void:
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online = false
	in_match = false
	players.clear()


func start_solo(opts: Dictionary) -> void:
	close()
	settings = {"mode": "1v1", "duration": int(opts.get("duration", 20)), "ai": int(opts.get("ai", 1)), "roles": false, "fill_ai": true}
	players = {1: {"name": my_name, "team": 0, "role": "boss"}}
	_launch()


func local_addresses() -> Array:
	var out := []
	for a in IP.get_local_addresses():
		if a.contains(":") or a.begins_with("127.") or a.begins_with("169.254"):
			continue
		out.append(a)
	# Radmin VPN раздаёт адреса 26.x.x.x — показываем их первыми.
	out.sort_custom(func(x, y): return x.begins_with("26.") and not y.begins_with("26."))
	return out


# --- Лобби -------------------------------------------------------------------
func request_team(team: int) -> void:
	if is_host():
		_change(1, "team", team)
	else:
		_rpc_change.rpc_id(1, "team", team)


func request_role(role: String) -> void:
	if is_host():
		_change(1, "role", role)
	else:
		_rpc_change.rpc_id(1, "role", role)


func set_setting(key: String, value) -> void:
	if not is_host():
		return
	settings[key] = value
	if key == "mode":
		_rebalance()
	_broadcast()


func start_match() -> void:
	if not is_host() or in_match:
		return
	_rpc_start.rpc(players, settings)


func _default_role(team: int) -> String:
	if settings.mode != "2v2" or not settings.roles:
		return "boss"
	for p in players.values():
		if p.team == team and p.role == "director":
			return "saboteur"
	return "director"


func _team_count(team: int, except_id := -1) -> int:
	var c := 0
	for id in players:
		if id != except_id and players[id].team == team:
			c += 1
	return c


func _rebalance() -> void:
	for id in players:
		var p: Dictionary = players[id]
		if _team_count(p.team, id) >= per_team():
			p.team = 1 - p.team
		if settings.mode != "2v2" or not settings.roles:
			p.role = "boss"
		elif p.role == "boss":
			p.role = _default_role(p.team)


func _change(id: int, field: String, value) -> void:
	if not players.has(id) or in_match:
		return
	var p: Dictionary = players[id]
	if field == "team":
		var t := clampi(int(value), 0, 1)
		if t != p.team and _team_count(t) < per_team():
			p.team = t
			if settings.mode == "2v2" and settings.roles:
				p.role = _default_role(t)
	elif field == "role" and Defs.ROLES.has(value):
		p.role = value
	_broadcast()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_change(field: String, value) -> void:
	if is_host():
		_change(multiplayer.get_remote_sender_id(), field, value)


func _broadcast() -> void:
	if online:
		_rpc_lobby.rpc(players, settings)
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _rpc_lobby(p: Dictionary, s: Dictionary) -> void:
	players = p
	settings = s
	lobby_changed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_register(pname: String, version: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	var reason := ""
	if version != Defs.VERSION:
		reason = "Разные версии игры (у хоста %s, у вас %s)." % [Defs.VERSION, version]
	elif in_match:
		reason = "Матч уже идёт."
	elif players.size() >= max_players():
		reason = "Лобби заполнено (%s)." % settings.mode
	if reason != "":
		_rpc_kick.rpc_id(id, reason)
		get_tree().create_timer(0.5).timeout.connect(func(): if _peer: _peer.disconnect_peer(id))
		return
	pname = pname.strip_edges().left(20)
	if pname == "":
		pname = "Игрок %d" % id
	var team := 0 if _team_count(0) <= _team_count(1) else 1
	players[id] = {"name": pname, "team": team, "role": _default_role(team)}
	Game.system_message("%s подключился" % pname)
	_broadcast()


@rpc("authority", "call_remote", "reliable")
func _rpc_kick(reason: String) -> void:
	close()
	disconnected.emit(reason)


@rpc("authority", "call_local", "reliable")
func _rpc_start(p: Dictionary, s: Dictionary) -> void:
	players = p
	settings = s
	_launch()


func _launch() -> void:
	in_match = true
	Game.prepare_match()
	get_tree().change_scene_to_file("res://scenes/Match.tscn")


# --- Сигналы сети ---------------------------------------------------------------
func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if not is_host() or not players.has(id):
		return
	var pname: String = players[id].name
	players.erase(id)
	if in_match:
		_rpc_lobby.rpc(players, settings)
		Game.on_players_changed()
		Game.system_message("%s отключился — его место занял ИИ" % pname)
	else:
		Game.system_message("%s отключился" % pname)
		_broadcast()


func _on_connected() -> void:
	_rpc_register.rpc_id(1, my_name, Defs.VERSION)
	connected_ok.emit()


func _on_connect_failed() -> void:
	close()
	connection_failed.emit("Не удалось подключиться. Проверьте IP, порт и что хост создал игру.")


func _on_server_gone() -> void:
	close()
	disconnected.emit("Хост закрыл игру или связь потеряна.")

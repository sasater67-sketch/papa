extends Node
## Сцена матча: мир + камера-стратег + хозяин от первого лица + интерфейс.

const World := preload("res://scripts/world/world.gd")
const CamRig := preload("res://scripts/world/cam_rig.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const FpPlayer := preload("res://scripts/fp/fp_player.gd")

var world: Node3D
var cam: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var fp_mode := false


func _ready() -> void:
	world = World.new()
	add_child(world)
	cam = CamRig.new()
	add_child(cam)
	cam.preset("overview", Net.my_team())
	cam.snap()
	player = CharacterBody3D.new()
	player.set_script(FpPlayer)
	player.team = Net.my_team()
	player.role = Net.my_role()
	player.world = world
	world.add_child(player)
	var slot := 0
	for id in Net.players:
		if id < multiplayer.get_unique_id() and int(Net.players[id].team) == player.team:
			slot += 1
	player.teleport(Game.spawn_pos(player.team, slot), PI if player.team == 0 else 0.0)
	hud = Hud.new()
	hud.cam = cam
	hud.player = player
	hud.match_node = self
	add_child(hud)
	Net.disconnected.connect(_on_disconnected)
	Sfx.music("casino", -18.0)
	Game.begin()


## Tab: стратегическая карта ↔ хозяин от первого лица.
func set_fp(on: bool) -> void:
	fp_mode = on
	player.set_active(on)
	cam.cam.current = not on
	cam.input_enabled = not on
	hud.set_fp(on)
	if not on:
		# камера-стратег смотрит туда, где стоит хозяин
		cam.target = Vector3(player.global_position.x, 2.0, player.global_position.z)
		cam.dist = 36.0


func _on_disconnected(reason: String) -> void:
	Game.stop()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Net.set_meta("menu_message", reason)
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

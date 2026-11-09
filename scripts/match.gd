extends Node
## Сцена матча: мир + камера + интерфейс.

const World := preload("res://scripts/world/world.gd")
const CamRig := preload("res://scripts/world/cam_rig.gd")
const Hud := preload("res://scripts/ui/hud.gd")


func _ready() -> void:
	var world: Node3D = World.new()
	add_child(world)
	var cam: Node3D = CamRig.new()
	add_child(cam)
	cam.preset("overview", Net.my_team())
	cam.snap()
	var hud: CanvasLayer = Hud.new()
	hud.cam = cam
	add_child(hud)
	Net.disconnected.connect(_on_disconnected)
	Game.begin()


func _on_disconnected(reason: String) -> void:
	Game.stop()
	get_tree().paused = false
	Net.set_meta("menu_message", reason)
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

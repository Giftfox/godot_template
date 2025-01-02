extends Node2D

signal scene_load_started()
signal scene_loaded()

var game_view: SubViewport
var game_container: SubViewportContainer
var gui_view: SubViewport
var dir = "src/scenes/"
var ext = ".tscn"

var gui
var current_room
var current_room_control
var current_room_path := ""
var new_room_entrance
var start_from_save := true

func load_scene(path: String) -> void:
	call_deferred("_load_scene_deferred", path)
	
func _load_scene_deferred(path: String) -> void:
	if game_view:
		emit_signal("scene_load_started")
		for n in game_view.get_children():
			if !n.is_in_group("no_destroy"):
				n.free()
		var pscene = load(dir + path + ext)
		var scene = pscene.instantiate()
		game_view.add_child(scene)
		scene.get_node("RoomControl").reposition()
		emit_signal("scene_loaded")
	else:
		push_error("Could not load scene - game viewport not found.")

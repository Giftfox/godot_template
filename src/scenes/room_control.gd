class_name RoomControl
extends Node2D

@export var has_player: bool = false
var scene_path: String = ""

@export var maintain_music = false
@export var force_clear_music = true
@export var music_mod := 1.0
var music_to_play := "Music"

var dir = "src/scenes/"
var ext = ".tscn"

signal fade_over(out)

func _ready():
	scene_path = get_parent().scene_file_path.substr("res://src/scenes/".length())
	scene_path = scene_path.substr(0, scene_path.length() - ".tscn".length())
	
	SceneManager.gui.connect("fade_finished",Callable(self,"fadetimer_over"))
	SceneManager.gui.fade_screen(false)
	
	SceneManager.current_room = get_parent()
	SceneManager.current_room_control = self
	SceneManager.current_room_path = scene_path
	
	Global.set_pause_state(Global.PauseState.TRANSITION)
	
	call_deferred("prep_music")
	
func reposition():
	SceneManager.gui.global_position = Vector2.ZERO
	get_viewport().canvas_transform.origin = Vector2.ZERO
	
func prep_music():
	if force_clear_music:
		SceneManager.game_view.get_node("Music").queue_maintain = false
	if get_node_or_null(music_to_play) and get_node(music_to_play).stream:
		var stream = get_node(music_to_play)
		SceneManager.game_view.get_node("Music").stop_track(true, [stream.stream.data])
		SceneManager.game_view.get_node("Music").play_track(stream.stream, !maintain_music, stream.volume_db, stream.pitch_scale)
	else:
		SceneManager.game_view.get_node("Music").stop_track()
	
func _process(delta):
	SceneManager.game_view.get_node("Music").set_db((50 + $Music.volume_db) * music_mod - 50)
	
func room_restart(from_save = false):
	room_change(SceneManager.current_room_path)
	
func room_change(path, preserve_entrance = false):
	Global.set_pause_state(Global.PauseState.TRANSITION)
	if has_player:
		Global.get_player().get_node("PlayerControls").fade_buffer = true
	fadeout()
	await SceneManager.gui.fade_finished
	room_end()
	
	SceneManager.load_scene(path)
	
func game_end():
	fadeout()
	await SceneManager.gui.fade_finished
	room_end()
	get_tree().quit()
	
func room_end():
	InputActions.buffered_inputs.clear()
	
	if SceneManager.current_room == get_parent():
		SceneManager.current_room = null
		SceneManager.current_room_control = null
		
	if has_player:
		Stats.player_direction = Global.get_player().get_node("Movement").facing
		
	if maintain_music:
		SceneManager.game_view.get_node("Music").queue_maintain = true
		
func play_music(trackname, clear = true):
	var n = get_node_or_null(trackname)
	if n and n.stream:
		if clear:
			SceneManager.game_view.get_node("Music").stop_track()
		SceneManager.game_view.get_node("Music").play_track(n.stream, true, n.volume_db, n.pitch_scale)
	
func stop_music():
	SceneManager.game_view.get_node("Music").stop_track()
	
func fade_music():
	SceneManager.game_view.get_node("Music").fadeout()
		
func fadeout():
	SceneManager.gui.fade_screen()

func fadetimer_over(out):
	if has_player:
		Global.get_player().get_node("PlayerControls").fade_buffer = false
	emit_signal("fade_over", out)
	if !out and Global.current_pausestate == Global.PauseState.TRANSITION:
		Global.set_pause_state(Global.PauseState.NORMAL)
		
func _exit_tree():
	DataManager.window_save()

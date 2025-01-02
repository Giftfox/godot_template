class_name HUD
extends Node2D

signal fade_finished(out)

var fade := 0

var open_menus := []

func _init():
	SceneManager.gui = self

func _ready():
	#Stats.connect("screen_set",Callable(self,"on_screen_set"))
	$ScreenFade.visible = true
	$ScreenFade/AnimationPlayer.play("unfade")
	
	#for i in range(Stats.inventory_size):
	#	var item = item_resource.instantiate()
	#	$HUD.add_child(item)
	#	item.position = Vector2(20 + 32 * i, 20)
	#	item.show_frame = true
	#	item.inventory_index = i

func _process(delta):
	if !$ScreenFade/AnimationPlayer.is_playing():
		if fade == -1:
			emit_signal("fade_finished", true)
		if fade == 1:
			emit_signal("fade_finished", false)
		fade = 0
		
	$HUD.visible = SceneManager.current_room_control and SceneManager.current_room_control.has_player and !SceneManager.current_room_control.hide_hud
	
func fade_screen(out = true):
	var fadenode = $ScreenFade/AnimationPlayer
	var current_pos = -1
	
	#if ($ScreenFade.modulate.a == 1.0 and out) or ($ScreenFade.modulate.a == 0.0 and !out):
	if ($ScreenFade.frame == 5 and out) or ($ScreenFade.frame == 0 and !out):
		emit_signal("fade_finished", out)
		fadenode.stop()
	else:
			
		if fadenode.is_playing():
			current_pos = fadenode.current_animation_position
		
		if out:
			fadenode.play("unfade", -1, -1, true)
			#fadenode.play("fade")
		else:
			fadenode.play("unfade")
			
		if current_pos >= 0:
			fadenode.seek(current_pos, true)
			
		if out:
			fade = -1
		else:
			fade = 1
			
func instant_fade(out = true, emit = true):
	$ScreenFade/AnimationPlayer.stop()
	if out:
		$ScreenFade.frame = 5
	else:
		$ScreenFade.frame = 0
	if emit:
		emit_signal("fade_finished", out)

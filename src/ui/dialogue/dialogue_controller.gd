class_name DialogueController
extends Node2D

var box_resource = preload("res://src/ui/dialogue/dialogue_box.tscn")
var portrait_resource = preload("res://src/ui/dialogue/dialogue_portrait.tscn")

var dialogue_queue := []

var current_box
var current_portrait

var active := false
var clearing := false

func _ready():
	Event.dialogue_handler = self

func _physics_process(delta):
	var alpha = 0.5 if active else 0.0
	#$Screen.modulate.a = Global.approach_value($Screen.modulate.a, alpha, 0.05 * delta * 60)
	
	if !clearing:
		update_dialogue()
	
	clearing = false
	
func update_dialogue(queue = []):
	if !queue.is_empty():
		dialogue_queue = queue
	
	if !dialogue_queue.is_empty():
		var next = true
		if Global.clear_object(current_box):
			next = current_box.clearable and Input.is_action_just_pressed("menu_confirm")
		
		if next:
			InputActions.skipped_inputs.append("menu_confirm")
			
			if Global.clear_object(current_box) and current_box.clearable and dialogue_queue[0].is_choice:
				var choice = current_box.choice_cursor - current_box.min_choice
				if dialogue_queue[0].choice_result_step[choice] != -1:
					if Event.current_source is EventTrigger:
						var src = Event.current_source
						Event.end_event(false, false)
						if !src.module_step(dialogue_queue[0].choice_result_step[choice]):
							Event.end_event()
					else:
						Event.set_step(dialogue_queue[0].choice_result_step[choice])
				elif dialogue_queue[0].choice_result_event[choice] != 0:
					var local_event = Event.current_local_event
					if Event.current_event == Event.Common.dialogue:
						local_event = Event.stored_local_event
					Event.run_event(dialogue_queue[0].choice_result_event[choice], Event.current_source, true, {}, local_event)
				else:
					Event.end_event()
				end_dialogue()
			else:
				if Global.clear_object(current_box):
					current_box.queue_free()
				if Global.clear_object(current_portrait):
					current_portrait.queue_free()
					
				if active:
					dialogue_queue.pop_front()
					
				if dialogue_queue.is_empty():
					end_dialogue()
				else:
					active = true
					var new_dialogue = dialogue_queue[0]
					
					current_box = box_resource.instantiate()
					add_child(current_box)
					
					var text = new_dialogue.get_all_text()
								
					if new_dialogue.is_choice:
						current_box.choosing = true
						
						current_box.queued_text = text
						current_box.get_node("Choice/Question").text = new_dialogue.choice_header
						if new_dialogue.choice_header != "":
							current_box.position.y -= 32
					else:
						current_box.queued_text = text
						
						current_box.position = Vector2(Global.VIEW_SIZE.x * Global.VIEW_SCALE / 2, Global.VIEW_SIZE.y * Global.VIEW_SCALE)
						
						current_portrait = null
						if new_dialogue.portrait != DialoguePortrait.portraits.none:
							current_portrait = portrait_resource.instantiate()
							add_child(current_portrait)
							current_portrait.portrait = new_dialogue.portrait
							current_portrait.position = Vector2(Global.VIEW_SIZE.x * Global.VIEW_SCALE * 0.125, Global.VIEW_SIZE.y * Global.VIEW_SCALE)
							
							if new_dialogue.portrait_on_left:
								current_box.position.x += 50
								current_portrait.position.x += 50
								current_box.get_node("Label").position.x += 100
							else:
								current_portrait.position.x = Global.VIEW_SIZE.x * Global.VIEW_SCALE - current_portrait.position.x
								current_portrait.scale.x = -1
								current_box.position.x -= 50
								current_portrait.position.x -= 50
							
							current_portrait.prepare()
						else:
							current_box.get_node("Label").position.x += 50

func end_dialogue():
	active = false
	clearing = true
	dialogue_queue.clear()
	if Global.clear_object(current_box):
		current_box.queue_free()
	if Global.clear_object(current_portrait):
		current_portrait.queue_free()
		
	if Global.get_player():
		Global.get_player().get_node("PlayerControls").manual_buffer = true

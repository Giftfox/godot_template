extends Node2D

var queued_text := []
var real_text := ""
var stopped := false
var clearable := false
var pointer := 0.0
var buffer_input := true

var choosing := false
var choice_cursor := 0
var min_choice := 0

func _process(delta):
	if !queued_text.is_empty():
		if !choosing:
			real_text = Global.split_text_into_lines(queued_text[0], 28)
			
			if real_text != "":
				var first = true
				while first or real_text[floor(pointer)] in ['\n', ' ']:
					pointer = Global.approach_value(pointer, real_text.length() - 1, 0.5 * delta * 60)
					first = false
			
			if pointer >= real_text.length() - 1:
				if queued_text.size() > 1:
					if Input.is_action_just_pressed("menu_confirm") and !buffer_input:
						pointer = 0
						queued_text.pop_front()
				else:
					if !stopped:
						stopped = true
						$Timer.start()
			else:
				if Input.is_action_just_pressed("menu_confirm") and !buffer_input:
					pointer = real_text.length() - 1
					
			$Label.text = real_text.substr(0, floor(pointer) + 1)
		else:
			if !stopped:
				stopped = true
				$Timer.start()
			min_choice = 0
			if queued_text.size() <= 2:
				min_choice = 1
					
			choice_cursor = max(choice_cursor, min_choice)
			var shift = Global.get_cardinal_input()
			if shift.y != 0:
				choice_cursor = Global.shift_index(choice_cursor, min_choice, min_choice + queued_text.size() - 1, shift.y)
			
			for i in range(4):
				var node = get_node("Choice/Answer" + str(i + 1))
				if queued_text.size() > i - min_choice and i - min_choice >= 0:
					node.text = queued_text[i - min_choice]
					if choice_cursor == i:
						node.modulate = Color(1.0, 1.0, 1.0)
					else:
						node.modulate = Color(0.6, 0.6, 0.6)
				else:
					node.text = ""
			
			$Choice.visible = true
			$Choice/Cursor.position.x = -get_node("Choice/Answer" + str(choice_cursor + 1)).text.length() / 2 * 12 - 128
			$Choice/Cursor.position.y = get_node("Choice/Answer" + str(choice_cursor + 1)).position.y + 24
	buffer_input = false


func _on_timer_timeout():
	clearable = true

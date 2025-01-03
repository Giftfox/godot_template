extends Area2D

@export var shrink := false

var hover_queue := []

func _process(delta):
	if can_input() and Input.is_action_just_pressed("click_left") or Input.is_action_just_pressed("click_right"):
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if Input.is_action_just_pressed("click_left") else MOUSE_BUTTON_RIGHT
		event.pressed = true
		event.position = Global.mouse_pos_shrink if shrink else Global.mouse_pos
		
		var params = PhysicsPointQueryParameters2D.new()
		params.position = event.position
		params.collide_with_areas = true
		var nodes_clicked = get_world_2d().direct_space_state.intersect_point(params)
		
		var clickzones = []
		for n in nodes_clicked:
			if n["collider"].is_in_group("clickzone"):
				clickzones.append(n["collider"])
				
		clickzones.sort_custom(_z_and_tree_order_descending)
		while clickzones.size() > 0 and !Global.buffer_mouse:
			clickzones.pop_back().manual_input(event)
		
func can_input():
	match Global.mouse_mode:
		Global.mouse_modes.normal:
			return true
		Global.mouse_modes.gui_only:
			return !shrink
		Global.mouse_modes.game_only:
			return shrink
	return false
		
func _tree_order_descending(a, b):
	if !Global.clear_object(a) or !Global.clear_object(b):
		return false
		
	var a_path := [a]
	var b_path := [b]
	while a_path.front().get_parent(): a_path.push_front(a_path.front().get_parent())
	while b_path.front().get_parent(): b_path.push_front(b_path.front().get_parent())

	for i in range(min(a_path.size(), b_path.size())):
		if a_path[i].get_index() != b_path[i].get_index():
			return a_path[i].get_index() < b_path[i].get_index()

	return a_path.size() < b_path.size()

func _z_order_descending(a, b):
	if !Global.clear_object(a) or !Global.clear_object(b):
		return false
		
	return Global.get_true_z_index(a) < Global.get_true_z_index(b)

func _z_and_tree_order_descending(a, b):
	if !Global.clear_object(a) or !Global.clear_object(b):
		return false
		
	if Global.get_true_z_index(a) == Global.get_true_z_index(b):
		return _tree_order_descending(a, b)
	else:
		return _z_order_descending(a, b)
	
func clickzone_entered(clickzone):
	var last
	if !hover_queue.is_empty():
		last = hover_queue[-1]
	hover_queue.append(clickzone)
	sort_hover_queue(last, true)

func clickzone_exited(clickzone):
	if !hover_queue.is_empty():
		var last = hover_queue[-1]
		hover_queue.erase(clickzone)
		call_deferred("sort_hover_queue", last, false)

func sort_hover_queue(last = null, entered = true):
	for clickzone in hover_queue:
		if !Global.clear_object(clickzone):
			hover_queue.erase(clickzone)
			
	if !hover_queue.is_empty():
		if !last:
			last = hover_queue[-1]
		hover_queue.sort_custom(_z_and_tree_order_descending)
		if (hover_queue.size() == 1 and entered) or hover_queue[-1] != last:
			if hover_queue[-1]:
				hover_queue[-1].mouse_active()

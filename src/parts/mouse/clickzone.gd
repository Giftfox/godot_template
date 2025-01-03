class_name Clickzone
extends Area2D

signal left_clicked()
signal right_clicked()
signal double_clicked()
signal left_released()
signal right_released()
signal mouse_activate()

var buffer := false
var left_held := false
var right_held := false
var mouse_in := false

enum cursor_types {
	none,
	press,
	move,
	mystery
}
@export var hover_cursor_type := cursor_types.none
@export var always_visible := false
@export var left_click_event := 0

@onready var detector = get_tree().get_first_node_in_group("input_detector")

var doubleclick_time := 0.0

#func _input_event(viewport, event, shape_idx):
#	if !buffer and is_visible_in_tree() and event is InputEventMouseButton and event.pressed:
#		buffer = true
#		if event.button_index == MOUSE_BUTTON_LEFT:
#			emit_signal("left_clicked")
#			_on_click(true)
#			left_held = true
#		if event.button_index == MOUSE_BUTTON_RIGHT:
#			emit_signal("right_clicked")
#			_on_click(false)
#			right_held = true
			
func manual_input(event):
	if !buffer and (is_visible_in_tree() or always_visible) and event is InputEventMouseButton and event.pressed:
		buffer = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			if doubleclick_time > 0.0:
				emit_signal("double_clicked")
				doubleclick_time = 0.0
			else:
				doubleclick_time = 1.0
			emit_signal("left_clicked")
			_on_click(true)
			left_held = true
			if left_click_event != 0:
				Event.run_event(left_click_event)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("right_clicked")
			_on_click(false)
			right_held = true

func _physics_process(delta):
	if mouse_in and !is_visible_in_tree():
		_on_mouse_exited()
	
	buffer = false
	if !Input.is_action_pressed("click_left"):
		if left_held and mouse_in:
			emit_signal("left_released")
		left_held = false
	if !Input.is_action_pressed("click_right"):
		if right_held and mouse_in:
			emit_signal("right_released")
		right_held = false
		
	doubleclick_time = Global.approach_value(doubleclick_time, 0, 0.1 * delta * 60)
	
func _on_click(left := true):
	pass

func _on_mouse_entered():
	mouse_in = true
	if !mouse_activate.get_connections().is_empty():
		detector.clickzone_entered(self)
	#if hover_cursor_type != cursor_types.none and !Global.gui.cursor_queue.has(self):
	#	Global.gui.cursor_queue.append(self)

func _on_mouse_exited():
	mouse_in = false
	if !mouse_activate.get_connections().is_empty():
		detector.clickzone_exited(self)
	#if Global.gui.cursor_queue.has(self):
	#	Global.gui.cursor_queue.erase(self)

func mouse_active():
	mouse_activate.emit()

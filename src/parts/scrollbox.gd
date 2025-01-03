@tool

class_name ScrollBox
extends Control

@export var allow_scrollwheel := true
@export var margin := Vector2.ZERO
@export var auto_resize := true
@export var auto_hide := true
@export_range(0.0, 1.0) var default_ratio := 0.0
@export var pip_size := 4
@onready var ratio := default_ratio

var inside_height := 0.0
var can_scroll := false

var pip_held := false
var pip_drag_threshold := 0.0
var pip_drag_start := 0.0

func _ready():
	$Bar/Clickzone/Coll.shape = $Bar/Clickzone/Coll.shape.duplicate()
	$Bar/Pip/Clickzone/Coll.shape = $Bar/Pip/Clickzone/Coll.shape.duplicate()

func _process(delta):
	if auto_resize:
		inside_height = 0
		
		for node in Global.get_family($InsideBox):
			if !node.is_in_group("no_size"):
				var bottom = node.global_position.y - $InsideBox.global_position.y
				if node is Sprite2D:
					if node.texture:
						bottom += node.texture.get_height() / node.hframes
				elif node is AnimatedSprite2D:
					if node.sprite_frames:
						bottom += node.sprite_frames.get_frame_texture(node.animation).get_height()
				elif node is Label or node is RichTextLabel or node is RectangleVisual:
					bottom += node.size.y
				inside_height = max(inside_height, bottom)
	
	$Bar/Pip.size.y = pip_size
	
	if pip_held and ($Bar/Pip/Clickzone.left_held or $Bar/Clickzone.left_held):
		if abs(pip_drag_start - Global.mouse_pos.y) > pip_drag_threshold:
			pip_drag_threshold = 0.0
		if pip_drag_threshold == 0.0:
			$Bar/Pip.global_position.y = Global.mouse_pos.y - $Bar/Pip.size.y / 2
			$Bar/Pip.position.y = clamp($Bar/Pip.position.y, 1, $Bar.size.y - $Bar/Pip.size.y)
			ratio = ($Bar/Pip.position.y - 1) / ($Bar.size.y - $Bar/Pip.size.y - 1)
	else:
		pip_held = false
	
	if can_scroll and allow_scrollwheel:
		var shift = 0
		if Input.is_action_just_released("wheel_up"): shift -= 1
		if Input.is_action_just_released("wheel_down"): shift = 1
		if shift != 0:
			ratio += 0.2 * shift
			ratio = clamp(ratio, 0.0, 1.0)
	
	var difference = max(inside_height - size.y, 0)
	$Bar.visible = true
	if auto_hide:
		$Bar.visible = difference > 0.0
		
	$Bar/Pip.position.y = 1 + round(($Bar.size.y - $Bar/Pip.size.y - 1) * ratio)
	$InsideBox.position.y = -difference * ratio
	
	$Bar.size.y = size.y - margin.y * 2
	$Bar.position = Vector2(size.x - $Bar.size.x - margin.x, margin.y)
	
	$Bar/Pip.size.x = $Bar.size.x
	$Bar/Pip.global_position.x = $Bar.global_position.x
	
	$Bar/Clickzone/Coll.shape.size = $Bar.size
	$Bar/Clickzone/Coll.global_position = $Bar.global_position + $Bar.size / 2
	$Bar/Pip/Clickzone/Coll.shape.size = $Bar/Pip.size
	$Bar/Pip/Clickzone/Coll.global_position = $Bar/Pip.global_position + $Bar/Pip.size / 2

func _on_bar_left_clicked():
	Global.buffer_mouse = true
	pip_held = true
	pip_drag_threshold = 0.0

func _on_pip_left_clicked():
	Global.buffer_mouse = true
	pip_held = true
	pip_drag_threshold = 5.0
	pip_drag_start = Global.mouse_pos.y

func _on_mouse_entered():
	can_scroll = true

func _on_mouse_exited():
	can_scroll = false

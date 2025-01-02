@tool

extends SubViewportContainer

func _process(delta):
	if Engine.is_editor_hint():
		size = Global.VIEW_SIZE * Global.VIEW_SCALE
		$GUIView.size = size

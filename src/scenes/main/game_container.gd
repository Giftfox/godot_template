@tool

extends SubViewportContainer

func _ready():
	if !Engine.is_editor_hint():
		#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		SceneManager.game_container = self
	
func _process(delta):
	if Engine.is_editor_hint():
		size = Global.VIEW_SIZE * Global.VIEW_SCALE
		stretch_shrink = Global.VIEW_SCALE

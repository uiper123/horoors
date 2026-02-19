extends CanvasLayer

func _ready() -> void:
	visible = false
	# Ensure this node processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_menu_pressed() -> void:
	toggle_pause() # Unpause first
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

extends Control

func _on_host_pressed() -> void:
	NetworkManager.host_game()
	visible = false

func _on_join_pressed() -> void:
	NetworkManager.join_game()
	visible = false

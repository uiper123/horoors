extends Interactable
class_name Door

@export var key_required: Item
@export var is_locked: bool = true

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var is_open: bool = false

func _on_interact(player: CharacterBody3D) -> void:
	if is_locked:
		if _player_has_key(player, key_required):
			is_locked = false
			print("Door unlocked with key.")
			AudioManager.play_sfx(preload("res://assets/sfx/unlock.wav"), global_position)
		else:
			print("Door is locked.")
			AudioManager.play_sfx(preload("res://assets/sfx/locked.wav"), global_position)
			return

	is_open = !is_open
	if is_open:
		animation_player.play("open")
		EventBus.door_opened.emit(name)
	else:
		animation_player.play("close")

func _player_has_key(player: CharacterBody3D, key: Item) -> bool:
	if not key:
		return true # No key needed
	
	# Assume player has an inventory component or array
	if player.has_method("has_item"):
		return player.has_item(key)
	
	return false # Default to false if no inventory system implemented yet

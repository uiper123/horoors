extends Area3D
class_name Interactable

# Base class for all interactable objects
# Attach this script to an Area3D node on the interactable object

signal interacted(player: CharacterBody3D)

func interact(player: CharacterBody3D) -> void:
	print("Interacted with: " + name)
	interacted.emit(player)
	_on_interact(player)

func _on_interact(player: CharacterBody3D) -> void:
	# Override this method in derived classes
	pass

extends RayCast3D
class_name InteractionComponent

# Component that handles RayCast interaction
# Attach this to the camera or player head

signal interaction_available(interactable: Interactable)
signal interaction_unavailable

@export var interaction_distance: float = 3.0

var current_interactable: Node

func _ready() -> void:
	target_position = Vector3(0, 0, -interaction_distance)
	collision_mask = GlobalSettings.LAYER_INTERACTABLE
	enabled = true

func _process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider != current_interactable:
			current_interactable = collider
			if collider is Interactable:
				interaction_available.emit(collider)
				EventBus.interactable_focused.emit(collider)
			elif collider.has_method("interact"):
				interaction_available.emit(null) # Generic interactable
	else:
		if current_interactable:
			current_interactable = null
			interaction_unavailable.emit()
			EventBus.interactable_unfocused.emit()

func interact(player: CharacterBody3D) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider is Interactable:
			collider.interact(player)
		elif collider.has_method("interact"):
			collider.interact(player)

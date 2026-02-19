extends State

# Interact State for Player

func enter() -> void:
	entity.velocity.x = 0
	entity.velocity.z = 0
	
	if not entity.is_multiplayer_authority():
		return

	# Perform interaction logic
	if entity.interaction_component.is_colliding():
		entity.interaction_component.interact(entity)
	
	# Transition back to Idle or Walk immediately after interaction check
	transition_requested.emit(self, "Idle")

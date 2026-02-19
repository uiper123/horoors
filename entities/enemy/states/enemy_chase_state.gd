extends State

# Chase State for Enemy

func enter() -> void:
	pass

func update(delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	if not entity.target:
		transition_requested.emit(self, "Patrol")
		return

	entity.navigation_agent.target_position = entity.target.global_position

	if entity.global_position.distance_to(entity.target.global_position) < entity.attack_range:
		transition_requested.emit(self, "Attack")
		return
	
	if entity.global_position.distance_to(entity.target.global_position) > entity.detection_range * 1.5:
		entity.target = null
		transition_requested.emit(self, "Patrol")
		return

	var next_path_position: Vector3 = entity.navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = (next_path_position - entity.global_position).normalized() * entity.speed
	entity.navigation_agent.set_velocity(new_velocity)

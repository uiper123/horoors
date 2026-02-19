extends State

# Attack State for Enemy

func enter() -> void:
	entity.velocity = Vector3.ZERO
	# Play attack animation
	if entity.animation_player:
		entity.animation_player.play("attack")
	
	# Deal damage logic here (simple example)
	if entity.target and entity.target.has_method("take_damage"):
		entity.target.take_damage(entity.damage)

func update(delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	if not entity.target or entity.global_position.distance_to(entity.target.global_position) > entity.attack_range:
		transition_requested.emit(self, "Chase")
		return

	# Wait for animation to finish or timer
	# For simplicity, assume immediate transition back after attack
	# In real game, use animation finished signal
	pass

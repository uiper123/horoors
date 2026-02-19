extends State

# Crouch State for Player

const ACCELERATION: float = 8.0
const DECELERATION: float = 10.0

func enter() -> void:
	entity.is_crouching = true

func exit() -> void:
	entity.is_crouching = false

func update(delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	# Handle input for movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var target_x = direction.x * entity.speed_crouch
		var target_z = direction.z * entity.speed_crouch
		
		entity.velocity.x = move_toward(entity.velocity.x, target_x, ACCELERATION * delta)
		entity.velocity.z = move_toward(entity.velocity.z, target_z, ACCELERATION * delta)
		
		# Optional: Add quieter footstep sounds or none
	else:
		entity.velocity.x = move_toward(entity.velocity.x, 0, DECELERATION * delta)
		entity.velocity.z = move_toward(entity.velocity.z, 0, DECELERATION * delta)

	if not Input.is_action_pressed("crouch"):
		if entity.velocity.length() > 0.1:
			transition_requested.emit(self, "Walk")
		else:
			transition_requested.emit(self, "Idle")
			
	if Input.is_action_just_pressed("interact"):
		transition_requested.emit(self, "Interact")

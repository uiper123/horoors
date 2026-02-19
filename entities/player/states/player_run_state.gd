extends State

# Run State for Player

var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.3

const ACCELERATION: float = 12.0
const DECELERATION: float = 10.0

func enter() -> void:
	footstep_timer = 0.0

func update(delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	# Handle input for movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var target_x = direction.x * entity.speed_run
		var target_z = direction.z * entity.speed_run
		entity.velocity.x = move_toward(entity.velocity.x, target_x, ACCELERATION * delta)
		entity.velocity.z = move_toward(entity.velocity.z, target_z, ACCELERATION * delta)
		
		footstep_timer -= delta
		if footstep_timer <= 0:
			entity.play_footstep()
			footstep_timer = FOOTSTEP_INTERVAL
	else:
		transition_requested.emit(self, "Idle")
		return

	if not Input.is_action_pressed("sprint"):
		transition_requested.emit(self, "Walk")

	if Input.is_action_pressed("crouch"):
		transition_requested.emit(self, "Crouch")

	if Input.is_action_just_pressed("interact"):
		transition_requested.emit(self, "Interact")

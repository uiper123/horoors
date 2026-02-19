extends State

# Idle State for Player

func enter() -> void:
	entity.velocity.x = 0
	entity.velocity.z = 0

func update(_delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		transition_requested.emit(self, "Walk")
	
	if Input.is_action_pressed("crouch"):
		transition_requested.emit(self, "Crouch")
	
	if Input.is_action_just_pressed("interact"):
		transition_requested.emit(self, "Interact")

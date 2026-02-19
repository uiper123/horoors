extends State

# Patrol State for Enemy
# Picks random points on NavigationMesh to patrol

@export var patrol_radius: float = 10.0
@export var wait_time: float = 2.0

var timer: float = 0.0
var has_target_pos: bool = false

func enter() -> void:
	timer = 0.0
	has_target_pos = false
	_set_new_patrol_point()

func update(delta: float) -> void:
	if not entity.is_multiplayer_authority():
		return

	# Check for player in range (simple distance check for now)
	var player = _find_nearest_player()
	if player and entity.global_position.distance_to(player.global_position) < entity.detection_range:
		entity.target = player
		transition_requested.emit(self, "Chase")
		return

	if not has_target_pos:
		timer -= delta
		if timer <= 0:
			_set_new_patrol_point()
		return

	if entity.navigation_agent.is_navigation_finished():
		has_target_pos = false
		timer = wait_time
		entity.velocity = Vector3.ZERO
		return

	var next_path_position: Vector3 = entity.navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = (next_path_position - entity.global_position).normalized() * entity.speed
	entity.navigation_agent.set_velocity(new_velocity)

func _set_new_patrol_point() -> void:
	var random_pos = entity.global_position + Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))
	entity.navigation_agent.target_position = random_pos
	has_target_pos = true

func _find_nearest_player() -> CharacterBody3D:
	# This is inefficient, better to use Group or Area3D detection
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		return players[0] # Just return the first one for now
	return null

extends CharacterBody3D
class_name Enemy

@export var speed: float = 3.0
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var damage: int = 10

@onready var state_machine: StateMachine = $StateMachine
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Optional

var target: CharacterBody3D

func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)
		return

	# Set up navigation
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movement logic is handled by StateMachine states
	# But applying velocity happens here via NavigationAgent callback or direct move_and_slide
	# If not using navigation agent velocity avoidance:
	# move_and_slide()

	# Sync position for others
	rpc("sync_transform", global_transform)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

@rpc("unreliable")
func sync_transform(new_transform: Transform3D) -> void:
	global_transform = new_transform

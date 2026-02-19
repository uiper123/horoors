extends CharacterBody3D
class_name Player

@export var speed_walk: float = 5.0
@export var speed_run: float = 8.0
@export var speed_crouch: float = 2.5

# Sway / Bobbing - Slowed down
@export var sway_amount: float = 0.05
@export var sway_speed: float = 1.5
@export var sway_yaw: float = 0.02
@export var sway_pitch: float = 0.01
@export var breath_amount: float = 0.02
@export var breath_speed: float = 0.8

var sway_timer: float = 0.0
var initial_camera_pos: Vector3
var initial_camera_rot: Vector3
var is_crouching: bool = false
var normal_height: float = 1.8
var crouch_height: float = 1.1

# Components
@onready var state_machine: StateMachine = $StateMachine
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_component: RayCast3D = $CameraPivot/Camera3D/InteractionComponent
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight
@onready var flashlight_sfx: AudioStreamPlayer = $FlashlightSfx
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@export var steps_grass: Array[AudioStream]
@export var steps_mud: Array[AudioStream]
@export var steps_wood: Array[AudioStream]
@export var steps_gravel: Array[AudioStream]

# Multiplayer
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	initial_camera_pos = camera.position
	initial_camera_rot = camera.rotation
	
	if is_multiplayer_authority():
		camera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera.current = false
		set_process_input(false)
		set_physics_process(false)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * GlobalSettings.mouse_sensitivity * 0.01)
		camera_pivot.rotate_x(-event.relative.y * GlobalSettings.mouse_sensitivity * 0.01)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	# Pass input to flashlight for sway
	if flashlight and flashlight.visible:
		flashlight._input(event)
	
	if event.is_action_pressed("flashlight"):
		if flashlight:
			flashlight.visible = !flashlight.visible
			if flashlight_sfx and flashlight_sfx.stream:
				flashlight_sfx.play()

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	_handle_sway(delta)
	_handle_crouch(delta)

func play_footstep() -> void:
	var surface = "grass" # Default
	
	if is_on_floor():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("wood"):
				surface = "wood"
				break
			elif collider.is_in_group("mud") or collider.is_in_group("wet"):
				surface = "mud"
				break
			elif collider.is_in_group("gravel") or collider.is_in_group("stone"):
				surface = "gravel"
				break
				
	match surface:
		"wood":
			if steps_wood.size() > 0: footstep_player.streams = steps_wood
		"mud":
			if steps_mud.size() > 0: footstep_player.streams = steps_mud
		"gravel":
			if steps_gravel.size() > 0: footstep_player.streams = steps_gravel
		_:
			if steps_grass.size() > 0: footstep_player.streams = steps_grass
			
	footstep_player.play_random()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movement logic is handled by StateMachine states
	# But applying velocity happens here
	move_and_slide()

	# Sync position for others (naive approach, better use MultiplayerSynchronizer node)
	rpc("sync_transform", global_transform)

@rpc("unreliable")
func sync_transform(new_transform: Transform3D) -> void:
	global_transform = new_transform

func _handle_sway(delta: float) -> void:
	var velocity_len = Vector3(velocity.x, 0, velocity.z).length()
	var is_moving = velocity_len > 0.1 and is_on_floor()
	
	if is_moving:
		sway_timer += delta * velocity_len * sway_speed
	else:
		sway_timer += delta * breath_speed
		
	var target_y = initial_camera_pos.y
	var target_x = initial_camera_pos.x
	var target_rot_z = initial_camera_rot.z
	var target_rot_x = initial_camera_rot.x
	
	if is_moving:
		# Walking bob - Figure 8 pattern
		target_y += sin(sway_timer * 2.0) * sway_amount
		target_x += cos(sway_timer) * sway_amount * 0.5
		
		# Rotational sway
		target_rot_z += cos(sway_timer) * sway_yaw
		target_rot_x += sin(sway_timer * 2.0) * sway_pitch
	else:
		# Breathing
		target_y += sin(sway_timer) * breath_amount
		target_x += cos(sway_timer * 0.5) * breath_amount * 0.2
		# Subtle rotation on breath
		target_rot_x += sin(sway_timer) * breath_amount * 0.1
		
	# Smoothly interpolate
	camera.position.y = lerp(camera.position.y, target_y, delta * 8.0)
	camera.position.x = lerp(camera.position.x, target_x, delta * 8.0)
	camera.rotation.z = lerp(camera.rotation.z, target_rot_z, delta * 8.0)
	camera.rotation.x = lerp(camera.rotation.x, target_rot_x, delta * 8.0)

func _handle_crouch(delta: float) -> void:
	var target_height = initial_camera_pos.y
	if is_crouching:
		target_height = initial_camera_pos.y - 0.7 # Lowers camera
		
		# Adjust collision (instant to avoid glitches)
		# Note: In a real game you'd check for overhead obstacles before standing up
		if collision_shape.shape.height != crouch_height:
			collision_shape.shape.height = crouch_height
			collision_shape.position.y = crouch_height / 2.0
	else:
		if collision_shape.shape.height != normal_height:
			# Check overhead obstruction here if needed
			collision_shape.shape.height = normal_height
			collision_shape.position.y = normal_height / 2.0
			
	# Apply camera height offset (on top of sway)
	# We modify 'initial_camera_pos.y' effectively for sway to work around it, 
	# but `_handle_sway` uses `initial_camera_pos.y` as base. 
	# So we should probably modify `camera_pivot.position.y` or similar. 
	# Actually, the camera is child of CameraPivot. 
	# Let's just lerp the CameraPivot's Y position.
	
	var target_pivot_y = 1.6 # Normal height
	if is_crouching:
		target_pivot_y = 1.1
		
	camera_pivot.position.y = lerp(camera_pivot.position.y, target_pivot_y, delta * 10.0)

extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $Monitor/Screen
@onready var camera_mount: Marker3D = $CameraMount
@onready var os_ui: Control = $SubViewport/PCOSUI

var is_active: bool = false
var player_ref: CharacterBody3D = null
var original_camera_transform: Transform3D

func _ready() -> void:
	# Ensure the texture is set to the viewport
	var material = StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Emissive look
	screen_mesh.material_override = material

func interact(player: CharacterBody3D) -> void:
	print("Interact received! Active:", is_active)
	if is_active: return
	
	is_active = true
	player_ref = player
	
	# Disable player movement/camera
	player_ref.set_physics_process(false)
	player_ref.set_process_input(false)
	
	# Store original camera pos
	var player_cam = player_ref.get_node("CameraPivot/Camera3D")
	original_camera_transform = player_cam.global_transform
	
	# Tween camera to screen
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(player_cam, "global_transform", camera_mount.global_transform, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_enable_ui_interaction()
	)

func exit_interaction() -> void:
	if not is_active: return
	
	is_active = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Tween back
	var player_cam = player_ref.get_node("CameraPivot/Camera3D")
	var tween = create_tween()
	tween.tween_property(player_cam, "global_transform", original_camera_transform, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
		player_ref = null
	)

func _enable_ui_interaction() -> void:
	# This is where we'd normally set up complex input forwarding.
	# For now, we assume the viewport handles GUI input if we feed it events.
	pass

func _input(event: InputEvent) -> void:
	if not is_active: return
	
	if event.is_action_pressed("ui_cancel"): # ESC
		exit_interaction()
		return
		
	# Forward mouse events to the SubViewport
	# Since the camera is directly in front of the screen (filling it mostly),
	# we can map screen coordinates to viewport coordinates.
	
	if event is InputEventMouse:
		var mouse_pos = event.position
		var viewport_size = get_viewport().get_visible_rect().size
		var sub_size = sub_viewport.size
		
		# Assuming the screen fills the view or is centered
		# Simple scaling (imperfect but works for 'fullscreen' zoom)
		# A proper implementation requires raycasting to the quad UVs.
		# For this prototype, we'll try direct forwarding which works if windows match size or scaling.
		
		# Let's clone the event to Avoid modifying the original
		var ev_copy = event.duplicate()
		# Scale position? 
		# If the subviewport is 512x512 and screen is 1920x1080...
		# We'll rely on the Area3D 'input_event' approach on the quad for better accuracy
		# But since we don't have that setup easily in script alone without collider setup:
		
		sub_viewport.push_input(ev_copy)
	else:
		sub_viewport.push_input(event)

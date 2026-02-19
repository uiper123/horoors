class_name ProceduralAnimator
extends Node

@export var skeleton_path: NodePath
@export var max_speed: float = 5.0

@export_group("Bone Names (Mixamo/Standard)")
@export var left_leg_name: String = "mixamorig_LeftUpLeg"
@export var right_leg_name: String = "mixamorig_RightUpLeg"
@export var left_arm_name: String = "mixamorig_LeftArm"
@export var right_arm_name: String = "mixamorig_RightArm"
@export var left_calf_name: String = "mixamorig_LeftLeg"
@export var right_calf_name: String = "mixamorig_RightLeg"
@export var left_foot_name: String = "mixamorig_LeftFoot"
@export var right_foot_name: String = "mixamorig_RightFoot"
@export var hips_name: String = "mixamorig_Hips"
@export var spine_name: String = "mixamorig_Spine"
@export var head_name: String = "mixamorig_Head"

@export_group("Animation Settings")
@export var arm_idle_angle: float = -50.0 # Degrees closer to vertical, but slightly forward
@export var leg_idle_angle: float = 0.0 # Adjust if legs are weird
@export var hide_head_locally: bool = true
@export var invert_knee_bend: bool = false

var skeleton: Skeleton3D
var left_leg_idx: int = -1
var right_leg_idx: int = -1
var left_calf_idx: int = -1
var right_calf_idx: int = -1
var left_foot_idx: int = -1
var right_foot_idx: int = -1
var left_arm_idx: int = -1
var right_arm_idx: int = -1
var hips_idx: int = -1
var spine_idx: int = -1
var head_idx: int = -1

# Smoothing
var current_crouch_blend: float = 0.0
var target_crouch_blend: float = 0.0
var current_speed_blend: float = 0.0

# Animation State
var time: float = 0.0
var walk_speed: float = 10.0
var arm_sway: float = 0.3
var leg_stride: float = 0.4 # Reduced from 0.8 for more realistic stride

func _ready() -> void:
	if not skeleton_path:
		# Try to find skeleton automatically
		var parent = get_parent()
		if parent is Skeleton3D:
			skeleton = parent
		else:
			skeleton = _find_skeleton_recursive(parent)
	else:
		skeleton = get_node(skeleton_path)
		
	if not skeleton:
		push_warning("ProceduralAnimator: No Skeleton3D found!")
		set_process(false)
		return
		
	# Find Bone Indices
	left_leg_idx = skeleton.find_bone(left_leg_name)
	right_leg_idx = skeleton.find_bone(right_leg_name)
	left_calf_idx = skeleton.find_bone(left_calf_name)
	right_calf_idx = skeleton.find_bone(right_calf_name)
	left_foot_idx = skeleton.find_bone(left_foot_name)
	right_foot_idx = skeleton.find_bone(right_foot_name)
	
	left_arm_idx = skeleton.find_bone(left_arm_name)
	right_arm_idx = skeleton.find_bone(right_arm_name)
	hips_idx = skeleton.find_bone(hips_name)
	spine_idx = skeleton.find_bone(spine_name)
	head_idx = skeleton.find_bone(head_name)
	
	# Fallback search if specific names aren't found
	if left_leg_idx == -1: _try_find_bones_alternative()

func _process(delta: float) -> void:
	var player = get_parent()
	while player and not player is CharacterBody3D:
		player = player.get_parent()
		
	if not player: return
	
	# Hide Head for Local Player
	if hide_head_locally and head_idx != -1:
		if player.is_multiplayer_authority():
			skeleton.set_bone_pose_scale(head_idx, Vector3.ZERO)
		else:
			skeleton.set_bone_pose_scale(head_idx, Vector3.ONE)
	
	var velocity = player.velocity
	var speed = Vector3(velocity.x, 0, velocity.z).length()
	
	# Crouch Blending
	target_crouch_blend = 1.0 if player.is_crouching else 0.0
	current_crouch_blend = lerp(current_crouch_blend, target_crouch_blend, delta * 10.0)
	
	# Speed Blending
	current_speed_blend = lerp(current_speed_blend, speed / max_speed, delta * 5.0)
	current_speed_blend = clamp(current_speed_blend, 0.0, 1.5)
	
	# Update Time
	# Reduced base speed multiplier (1.2 instead of 1.5) and frequency increase
	var frequency_mult = 1.0 + (0.2 * current_speed_blend)
	time += delta * speed * 1.2 * frequency_mult
	
	# --- Base Poses (Crouch vs Stand) ---
	# Crouch: Thighs forward (~60 deg), Calves back (~-110 deg)
	var crouch_thigh_rad = deg_to_rad(70.0)
	var crouch_calf_rad = deg_to_rad(-110.0)
	var crouch_spine_rad = deg_to_rad(25.0) # Lean forward
	
	var thigh_offset = lerp(0.0, crouch_thigh_rad, current_crouch_blend)
	var calf_offset = lerp(0.0, crouch_calf_rad, current_crouch_blend)
	var spine_offset_pitch = lerp(0.0, crouch_spine_rad, current_crouch_blend)
	
	# --- Walk Cycle Math ---
	# Left Leg Phase: 0, Right Leg Phase: PI
	var left_phase = time
	var right_phase = time + PI
	
	var walk_intensity = current_speed_blend
	if invert_knee_bend: walk_intensity = -walk_intensity
	
	# Thigh Swing (Main stride)
	var l_thigh_swing = sin(left_phase) * leg_stride * walk_intensity
	var r_thigh_swing = sin(right_phase) * leg_stride * walk_intensity
	
	# Calf Bend (Lift leg up during swing)
	# Maximize bend when thigh is swinging forward (lifting foot)
	var calf_bend_amount = 0.6 # Reduced from 1.2 to avoid "high knees" / childish walk
	var l_calf_walk = max(0, sin(left_phase + 0.5)) * calf_bend_amount * walk_intensity
	var r_calf_walk = max(0, sin(right_phase + 0.5)) * calf_bend_amount * walk_intensity
	
	# --- Apply Rotations (Relative to Rest) ---
	
	# Helper lambda for bone rotation
	var apply_rot = func(idx: int, q_euler: Quaternion):
		if idx == -1: return
		var rest = skeleton.get_bone_rest(idx).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(idx, rest * q_euler)

	# LEGS (Thighs)
	# Add crouch offset + walk swing
	var q_thigh_l = Quaternion(Vector3.RIGHT, thigh_offset + l_thigh_swing)
	var q_thigh_r = Quaternion(Vector3.RIGHT, thigh_offset + r_thigh_swing)
	apply_rot.call(left_leg_idx, q_thigh_l)
	apply_rot.call(right_leg_idx, q_thigh_r)
	
	# CALVES (Lower Legs)
	# Add crouch offset + walk bend
	# Note: Knees usually bend strictly on one axis (negative X usually for Mixamo)
	var q_calf_l = Quaternion(Vector3.RIGHT, calf_offset - l_calf_walk)
	var q_calf_r = Quaternion(Vector3.RIGHT, calf_offset - r_calf_walk) # Negative because knees bend back
	apply_rot.call(left_calf_idx, q_calf_l)
	apply_rot.call(right_calf_idx, q_calf_r)
	
	# ARMS
	# Arm Swing opposite to legs
	var arm_swing_amp = arm_sway * walk_intensity
	var l_arm_swing = cos(left_phase) * arm_swing_amp
	var r_arm_swing = cos(right_phase) * arm_swing_amp
	
	# Arm Idle/Base
	var arm_base_rad = deg_to_rad(arm_idle_angle)
	var arm_forward_tilt = deg_to_rad(10.0) # Angle arms slightly forward so they are visible
	
	if left_arm_idx != -1:
		var q_base = Quaternion(Vector3.FORWARD, arm_base_rad) # Lower
		var q_forward = Quaternion(Vector3.UP, arm_forward_tilt) # Forward tilt (assuming Y-up relative)
		# Actually, for Mixamo, Forward is Z usually? No, let's try rotating around local axis.
		# Mixamo T-Pose: X is usually along the arm. Y is up/back. Z is forward/down.
		# Let's rotate around WORLD Y relative to the shoulder? Hard to do simply.
		# Let's just adjust the mix of rotations.
		# Adding a slight X rotation (pitch forward) might work if Z was 'down'.
		var q_pitch = Quaternion(Vector3.RIGHT, deg_to_rad(15.0))
		
		var q_swing = Quaternion(Vector3.RIGHT, -l_arm_swing) # Swing
		apply_rot.call(left_arm_idx, q_base * q_pitch * q_swing)
		
	if right_arm_idx != -1:
		var q_base = Quaternion(Vector3.FORWARD, -arm_base_rad)
		var q_pitch = Quaternion(Vector3.RIGHT, deg_to_rad(15.0))
		var q_swing = Quaternion(Vector3.RIGHT, r_arm_swing) 
		apply_rot.call(right_arm_idx, q_base * q_pitch * q_swing)
		

	# HIPS / ROOT (Vertical movement)
	# This avoids the camera "sinking" into a standing mesh.
	# We lower the hips physically.
	if hips_idx != -1:
		var crouch_drop = lerp(0.0, -0.6, current_crouch_blend) # Move hips down 0.6 units
		var walk_bounce_y = abs(sin(time * 2.0)) * 0.05 * current_speed_blend # Double freq bounce
		
		# Apply Position Offset (Relative to Rest)
		var rest_pos = skeleton.get_bone_rest(hips_idx).origin
		var target_pos = rest_pos + Vector3(0, crouch_drop + walk_bounce_y, 0)
		skeleton.set_bone_pose_position(hips_idx, target_pos)
		
	# SPINE / BODY
	# Bounce (Vertical) - Affects Hips/Root usually, but we move Spine rotation for "leaning"
	# Ideally we'd move the hip BONE position down for crouch, but we are just rotating here.
	if spine_idx != -1:
		var spine_sway_y = cos(time * 0.5) * 0.1 * current_speed_blend
		var q_spine = Quaternion.from_euler(Vector3(spine_offset_pitch, spine_sway_y, 0))
		apply_rot.call(spine_idx, q_spine)
		
	# Adjust Hips Height (Bonus: if user has a Hip/Root bone separate from legs)
	# Since this is a simple script, we stick to rotations. 
	# The actual collision crouch lowers the whole mesh via the Player script (kinda).
	# But visualized crouch needs the legs to pull the body down visually.
	# Since we don't use IK, the feet might clip into ground or float.
	# But rotating thighs UP and calves BACK essentially shorten the legs, simulating crouch.

func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	for child in node.get_children():
		if child is Skeleton3D:
			return child
		var res = _find_skeleton_recursive(child)
		if res: return res
	return null

func _try_find_bones_alternative() -> void:
	# Common Blender names
	left_leg_idx = skeleton.find_bone("Thigh.L")
	if left_leg_idx == -1: left_leg_idx = skeleton.find_bone("Leg.L")
	left_calf_idx = skeleton.find_bone("Shin.L")
	if left_calf_idx == -1: left_calf_idx = skeleton.find_bone("LowerLeg.L")
	
	right_leg_idx = skeleton.find_bone("Thigh.R")
	if right_leg_idx == -1: right_leg_idx = skeleton.find_bone("Leg.R")
	right_calf_idx = skeleton.find_bone("Shin.R")
	if right_calf_idx == -1: right_calf_idx = skeleton.find_bone("LowerLeg.R")
	
	left_arm_idx = skeleton.find_bone("UpperArm.L")
	right_arm_idx = skeleton.find_bone("UpperArm.R")
	
	hips_idx = skeleton.find_bone("Hips")
	if hips_idx == -1: hips_idx = skeleton.find_bone("Pelvis")

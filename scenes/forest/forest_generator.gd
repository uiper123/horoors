@tool
extends Node3D

@export var tree_count: int = 200
@export var bush_count: int = 150
@export var area_size: float = 80.0

@export_group("Scale Settings")
@export var tree_scale_min: float = 0.5
@export var tree_scale_max: float = 1.2
@export var bush_scale_min: float = 0.3
@export var bush_scale_max: float = 0.6

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	var ps1_shader = load("res://ui/ps1_model.gdshader")
	
	_generate_objects("tree", 36, tree_count, ps1_shader, tree_scale_min, tree_scale_max)
	_generate_objects("bush", 8, bush_count, ps1_shader, bush_scale_min, bush_scale_max)

func _generate_objects(type: String, max_index: int, count: int, shader: Shader, min_s: float, max_s: float) -> void:
	for i in range(count):
		var idx = randi_range(1, max_index)
		var idx_str = "%02d" % idx
		
		# Load Model
		var model_path = "res://assets/tree_pack_1.1/models/%s%s.fbx" % [type, idx_str]
		if not ResourceLoader.exists(model_path):
			continue
			
		var scene = load(model_path)
		if not scene:
			continue
			
		var instance = scene.instantiate()
		
		# Load Texture
		var tex_path = "res://assets/tree_pack_1.1/textures/%s%s.png" % [type, idx_str]
		var texture = null
		if ResourceLoader.exists(tex_path):
			texture = load(tex_path)
			
		# Position
		var x = randf_range(-area_size, area_size)
		var z = randf_range(-area_size, area_size)
		
		# Spawn Safe Zone
		if Vector2(x, z).length() < 8.0:
			instance.queue_free()
			continue
			
		instance.position = Vector3(x, 0, z)
		instance.rotation.y = randf() * TAU
		
		# Scale variation
		var s = randf_range(min_s, max_s)
		instance.scale = Vector3(s, s, s)
		
		add_child(instance)
		
		# Apply Shader to Meshes and Setup Collision
		var w_mult = 1.0
		if type == "bush": w_mult = 2.5
		_apply_shader_recursive(instance, shader, texture, w_mult)

func _apply_shader_recursive(node: Node, shader: Shader, texture: Texture2D, wind_mult: float = 1.0) -> void:
	if node is MeshInstance3D:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		if texture:
			mat.set_shader_parameter("albedo_texture", texture)
		else:
			# Fallback color if no texture
			mat.set_shader_parameter("albedo_color", Color(0.1, 0.2, 0.1))
			
		mat.set_shader_parameter("fog_color", Color(0.05, 0.06, 0.08))
		mat.set_shader_parameter("fog_start", 5.0)
		mat.set_shader_parameter("fog_end", 30.0) 
		mat.set_shader_parameter("alpha_scissor", 0.5)
		
		# Wind
		mat.set_shader_parameter("wind_speed", randf_range(0.8, 1.2))
		mat.set_shader_parameter("wind_strength", randf_range(0.1, 0.2) * wind_mult)
		
		node.material_override = mat
		node.visibility_range_end = 60.0
		node.visibility_range_end_margin = 10.0
		
		# Create collision (StaticBody3D)
		# Improved: Only create if not already present/too complex
		if node.get_child_count() == 0: 
			node.create_trimesh_collision()
			
	for child in node.get_children():
		_apply_shader_recursive(child, shader, texture, wind_mult)

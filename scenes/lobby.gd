extends Node3D

@onready var char_container: Node3D = $Characters
@onready var name_label: Label = $CanvasLayer/Control/NameLabel

var char_models: Array[Node3D] = []
var char_names = ["The Survivor", "The Hunter"] 

func _ready() -> void:
	# Hide placeholders
	for child in char_container.get_children():
		child.visible = false
		
	# Load models
	var model1 = load("res://assets/Characters/Character_01/Character_01.fbx").instantiate()
	char_container.add_child(model1)
	model1.position = Vector3(-1.5, 0, 0)
	model1.rotation_degrees.y = 15
	char_models.append(model1)
	
	var model2 = load("res://assets/Characters/Killer_01/Killer_01.fbx").instantiate()
	char_container.add_child(model2)
	model2.position = Vector3(1.5, 0, 0)
	model2.rotation_degrees.y = -15
	char_models.append(model2)
	
	# Start rotating animations
	for m in char_models:
		var tween = create_tween().set_loops()
		tween.tween_property(m, "rotation:y", deg_to_rad(360), 8.0).as_relative()
		
	update_selection()

func _on_prev_pressed() -> void:
	GlobalSettings.selected_character = 0
	update_selection()

func _on_next_pressed() -> void:
	GlobalSettings.selected_character = 1
	update_selection()

func update_selection() -> void:
	var idx = GlobalSettings.selected_character
	name_label.text = char_names[idx]
	
	# Scale effect
	for i in range(char_models.size()):
		var target_scale = Vector3(1.2, 1.2, 1.2) if i == idx else Vector3(0.9, 0.9, 0.9)
		create_tween().tween_property(char_models[i], "scale", target_scale, 0.2)
		
	# Focus effect (optional light or position change)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/forest/forest_level.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

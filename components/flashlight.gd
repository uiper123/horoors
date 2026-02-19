extends SpotLight3D

@export var follow_speed: float = 15.0
@export var sway_amount: float = 0.5
@export var noise_speed: float = 5.0
@export var noise_intensity: float = 0.05

var target_rotation: Vector3
var noise: FastNoiseLite = FastNoiseLite.new()
var time: float = 0.0
var base_energy: float

func _ready() -> void:
	base_energy = light_energy
	noise.seed = randi()
	noise.frequency = 2.0

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
		
	# Subtle flicker
	time += delta * noise_speed
	var flicker = noise.get_noise_1d(time) * noise_intensity
	light_energy = base_energy + flicker
	
	# Smoothly return to center
	rotation.y = lerp(rotation.y, 0.0, delta * follow_speed)
	rotation.x = lerp(rotation.x, 0.0, delta * follow_speed)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	if event is InputEventMouseMotion:
		var target_y = -event.relative.x * sway_amount * 0.001
		var target_x = -event.relative.y * sway_amount * 0.001
		
		# Add immediate "drag"
		rotation.y += target_y
		rotation.x += target_x
		
		# Clamp
		rotation.x = clamp(rotation.x, -0.3, 0.3)
		rotation.y = clamp(rotation.y, -0.3, 0.3)

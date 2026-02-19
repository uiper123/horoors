extends OmniLight3D

@export var min_energy: float = 0.5
@export var max_energy: float = 1.5
@export var flicker_speed: float = 10.0

var noise: FastNoiseLite = FastNoiseLite.new()
var time: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.1 # Adjust for noise characteristics

func _process(delta: float) -> void:
	time += delta * flicker_speed
	var value = noise.get_noise_1d(time)
	light_energy = lerp(min_energy, max_energy, (value + 1.0) / 2.0)

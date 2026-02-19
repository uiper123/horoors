extends AudioStreamPlayer3D
class_name RandomAudioStreamPlayer

@export var streams: Array[AudioStream]
@export var pitch_min: float = 0.9
@export var pitch_max: float = 1.1

func play_random() -> void:
	if streams.is_empty():
		return
		
	stream = streams.pick_random()
	pitch_scale = randf_range(pitch_min, pitch_max)
	play()

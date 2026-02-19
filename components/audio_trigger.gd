extends Area3D

@export var audio_stream: AudioStream
@export var one_shot: bool = true
@export var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

@export var random_start: bool = false
@export var trim_start_time: float = 0.0

func _on_body_entered(body: Node3D) -> void:
	if one_shot and triggered:
		return
		
	if body is CharacterBody3D and body.is_multiplayer_authority():
		# Play locally for the player who entered
		if audio_stream:
			var start = trim_start_time
			if random_start:
				start = randf_range(0.0, audio_stream.get_length() * 0.5)
				
			AudioManager.play_sfx(audio_stream, global_position, 1.0, 0.0, start)
		triggered = true

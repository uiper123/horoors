extends Node

# Global Audio Manager to handle all sound playback
# Usage: AudioManager.play_sfx("res://assets/sfx/footstep.wav", global_position)

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var sfx_pool: Array[AudioStreamPlayer3D] = []
const POOL_SIZE: int = 32

func _ready() -> void:
	add_child(music_player)
	
	# Create a pool of AudioStreamPlayer3D for efficient SFX playback
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer3D.new()
		player.bus = "SFX"
		player.unit_size = 10.0 # Adjust for PS1 scale if needed
		player.max_distance = 20.0
		add_child(player)
		sfx_pool.append(player)

func play_sfx(stream: AudioStream, position: Vector3 = Vector3.ZERO, pitch_scale: float = 1.0, volume_db: float = 0.0, trim_start: float = 0.0, trim_end: float = 0.0) -> void:
	if not stream:
		return
		
	var player = _get_available_player()
	if player:
		player.stream = stream
		player.global_position = position
		player.pitch_scale = pitch_scale
		player.volume_db = volume_db
		
		# For random start/trimming, we need to seek
		# Note: seek() only works if the stream is playing, but we want to start from there.
		# For AudioStreamPlayer3D, we call play(from_position)
		
		var start_pos = trim_start
		if trim_end > trim_start:
			# Just a simple way to play a segment or random start if needed
			pass
		
		player.play(start_pos)

func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
		
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func _get_available_player() -> AudioStreamPlayer3D:
	for player in sfx_pool:
		if not player.playing:
			return player
	
	# If all players are busy, stop the oldest one (simple heuristic) or just return the first one
	# For simplicity, we'll reuse the first one
	return sfx_pool[0]

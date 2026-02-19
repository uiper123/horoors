extends Node3D

@export var player_scene: PackedScene
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	# Register spawnable scenes for multiplayer
	if player_scene:
		spawner.add_spawnable_scene(player_scene.resource_path)

	# Connect to NetworkManager signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	
	# If we are the host (server), we spawn our own player immediately after hosting
	# But NetworkManager emits player_connected(1) when hosting, so it's covered.
	
	# Start Ambient Music
	var music = load("res://assets/Fog In The Dollhouse.mp3")
	if music:
		AudioManager.play_music(music, -10.0)

func _on_player_connected(id: int) -> void:
	# Only the server spawns players
	if not multiplayer.is_server():
		return
		
	print("Spawning player for ID: ", id)
	var player = player_scene.instantiate()
	player.name = str(id)
	player.global_position = Vector3(0, 1, 0)
	add_child(player, true)

func _on_player_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
		
	if has_node(str(id)):
		get_node(str(id)).queue_free()

func _on_server_disconnected() -> void:
	# Cleanup or return to menu
	get_tree().reload_current_scene()

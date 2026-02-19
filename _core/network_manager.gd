extends Node

# Handles multiplayer connection setup

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_disconnected

const DEFAULT_PORT: int = 7777
const MAX_CLIENTS: int = 4

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func host_game() -> void:
	var error = peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	if error != OK:
		push_error("Cannot host game: " + str(error))
		return
	multiplayer.multiplayer_peer = peer
	player_connected.emit(multiplayer.get_unique_id())

func join_game(address: String = "localhost") -> void:
	var error = peer.create_client(address, DEFAULT_PORT)
	if error != OK:
		push_error("Cannot join game: " + str(error))
		return
	multiplayer.multiplayer_peer = peer

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Player connected: " + str(id))
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: " + str(id))
	player_disconnected.emit(id)

func _on_server_disconnected() -> void:
	print("Server disconnected")
	server_disconnected.emit()

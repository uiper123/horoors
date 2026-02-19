extends Node
class_name StateMachine

# Finite State Machine Component
# Manages state transitions and synchronization

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Register all states
	for child in get_children():
		if child is State:
			states[child.state_name] = child
			child.transition_requested.connect(_on_transition_requested)
			child.entity = get_parent() # Assume parent is the entity (CharacterBody3D)
	
	if initial_state:
		_transition_to(initial_state)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _transition_to(new_state: State) -> void:
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
	
	# Multiplayer: Sync state change
	if multiplayer.has_multiplayer_peer():
		rpc("_sync_state_change", new_state.state_name)

func _on_transition_requested(from_state: State, to_state_name: String) -> void:
	if from_state != current_state:
		return # Avoid invalid transitions
		
	var new_state = states.get(to_state_name)
	if new_state:
		_transition_to(new_state)

@rpc("authority", "call_local", "reliable")
func _sync_state_change(state_name: String) -> void:
	# Only peers should sync, the authority already changed
	if not multiplayer.is_server() and multiplayer.get_unique_id() != 1:
		var new_state = states.get(state_name)
		if new_state and new_state != current_state:
			_transition_to(new_state)

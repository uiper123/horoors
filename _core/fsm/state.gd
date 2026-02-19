extends Node
class_name State

# Base State for FSM
# All methods are virtual and should be overridden

signal transition_requested(from_state: State, to_state_name: String)

@export var state_name: String
var entity: CharacterBody3D # Reference to the owner (Player or Enemy)

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

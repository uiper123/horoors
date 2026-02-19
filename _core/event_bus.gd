extends Node

# Global Event Bus for decoupled communication
# Usage: EventBus.player_health_changed.emit(new_health)

signal player_health_changed(new_health: int)
signal player_died
signal interactable_focused(interactable: Node)
signal interactable_unfocused
signal door_opened(door_id: String)

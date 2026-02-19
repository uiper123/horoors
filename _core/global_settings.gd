extends Node

# Global Settings & Constants

const LAYER_WORLD: int = 1
const LAYER_INTERACTABLE: int = 2
const LAYER_PLAYER: int = 4
const LAYER_ENEMY: int = 8

const INTERACTION_DISTANCE: float = 3.0

var mouse_sensitivity: float = 0.3
var volume_master: float = 1.0
var volume_sfx: float = 1.0
var volume_music: float = 1.0

var selected_character: int = 0

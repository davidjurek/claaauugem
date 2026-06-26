class_name Portal
extends Area2D
## Walk-over area that sends the player to another world. Optionally gated by a
## flag (e.g. a locked door until you have the key).

@export_file("*.tscn") var target_scene: String
@export var target_spawn: String = "default"
@export var require_flag: String = ""        # if set, only works once flag is true
@export var locked_message: String = ""

var _used := false

func _ready() -> void:
	collision_mask = 1
	body_entered.connect(_on_body)

func _on_body(body: Node) -> void:
	if _used or not (body is Player):
		return
	if require_flag != "" and not GameState.get_flag(require_flag):
		if locked_message != "":
			body.set_movement_locked(false)
		return
	_used = true
	var main := get_tree().current_scene
	if main and main.has_method("change_world"):
		main.change_world(load(target_scene), target_spawn)

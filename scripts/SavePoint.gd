class_name SavePoint
extends StaticBody2D
## EarthBound-style "call home to save" point — a pay phone. Solid + interactable.
## The actual save happens inside the dialogue via `do GameState.save_game()`.

@export_file("*.dialogue") var dialogue_path: String = "res://data/dialogue/system.dialogue"
@export var dialogue_title: String = "phone"

var _busy := false

func interact(player: Player) -> void:
	if _busy:
		return
	_busy = true
	player.set_movement_locked(true)
	var res: DialogueResource = load(dialogue_path)
	var balloon := DialogueManager.show_example_dialogue_balloon(res, dialogue_title)
	await balloon.tree_exited
	player.set_movement_locked(false)
	_busy = false

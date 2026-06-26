extends Node
## Dev-only: spin up a battle so it can be screenshotted / smoke-tested.
## `-- --auto` makes the hero auto-fight and prints the result, for headless CI.
@export var enemy_ids: Array = ["lawn_slurry", "toadstool"]
@export var boss := false

func _ready() -> void:
	GameState.reset()
	GameState.party = ["pidge"]
	var args := OS.get_cmdline_user_args()
	var ids: Array = enemy_ids
	var b = preload("res://scenes/battle/Battle.tscn").instantiate()
	if args.has("--auto"):
		b.auto_play = true
		b.fast = true
	b.setup(ids, boss)
	b.battle_finished.connect(_on_done)
	add_child(b)

func _on_done(result: String) -> void:
	print("[BATTLETEST] result=%s level=%d money=%d hp=%d/%d exp=%d" % [
		result, GameState.stats.level, GameState.money,
		GameState.stats.hp, GameState.stats.max_hp, GameState.stats.exp])
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if result in ["win", "ran"] else 2)

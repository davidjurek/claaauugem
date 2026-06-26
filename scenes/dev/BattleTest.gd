extends Node
## Dev-only battle harness. Args:
##   --auto            hero auto-fights, prints result
##   --enemies a,b,c   troop (default lawn_slurry,toadstool)
##   --boss            boss battle
##   --level N         level the hero up to N first
@export var enemy_ids: Array = ["lawn_slurry", "toadstool"]
@export var boss := false

func _ready() -> void:
	GameState.reset()
	GameState.party = ["pidge"]
	var args := OS.get_cmdline_user_args()
	var ids: Array = enemy_ids
	var bossv: bool = boss
	var ei := args.find("--enemies")
	if ei != -1 and ei + 1 < args.size():
		ids = args[ei + 1].split(",")
	if args.has("--boss"):
		bossv = true
	var li := args.find("--level")
	if li != -1 and li + 1 < args.size():
		var target := int(args[li + 1])
		while GameState.stats.level < target:
			GameState.add_exp(GameState.exp_to_next())
	var b = preload("res://scenes/battle/Battle.tscn").instantiate()
	if args.has("--auto"):
		b.auto_play = true
		b.fast = true
	b.setup(ids, bossv)
	b.battle_finished.connect(_on_done)
	add_child(b)

func _on_done(result: String) -> void:
	print("[BATTLETEST] result=%s level=%d money=%d hp=%d/%d" % [
		result, GameState.stats.level, GameState.money,
		GameState.stats.hp, GameState.stats.max_hp])
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if result in ["win", "ran"] else 2)

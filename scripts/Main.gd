extends Node
## Game root. Loads a world, spawns the single player at a named spawn point,
## overlays touch controls, drives world music, and runs battles as overlays.

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const TOUCH_SCENE := preload("res://scenes/ui/TouchControls.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/Battle.tscn")

@export var start_world: PackedScene = preload("res://scenes/world/TownSquare.tscn")

var world: GameWorld
var player: Player
var touch: CanvasLayer
var in_battle := false

func _ready() -> void:
	var ws: String = GameState.current_world
	var scene: PackedScene = load(ws) if ResourceLoader.exists(ws) else start_world
	change_world(scene, GameState.current_spawn)
	touch = TOUCH_SCENE.instantiate()
	add_child(touch)

func change_world(scene: PackedScene, spawn := "default") -> void:
	if world and is_instance_valid(world):
		world.queue_free()
	world = scene.instantiate()
	add_child(world)
	player = PLAYER_SCENE.instantiate()
	player.position = world.spawn_points.get(spawn, Vector2.ZERO)
	world.entities.add_child(player)
	GameState.current_world = scene.resource_path
	GameState.current_spawn = spawn
	AudioManager.play_bgm(world.music_path)

## Start a battle as a paused overlay. Returns "win"/"lose"/"ran".
func start_battle(enemy_ids: Array, boss := false) -> String:
	if in_battle:
		return "ran"
	in_battle = true
	if player:
		player.set_movement_locked(true)
	AudioManager.play_bgm("res://audio/battle/boss.ogg" if boss else "res://audio/battle/battle1.ogg", true)
	await _flash()
	var battle = BATTLE_SCENE.instantiate()
	battle.process_mode = Node.PROCESS_MODE_ALWAYS
	battle.setup(enemy_ids, boss)
	add_child(battle)
	get_tree().paused = true
	var result: String = await battle.battle_finished
	get_tree().paused = false
	in_battle = false
	if result == "lose":
		await _handle_defeat()
	elif GameState.get_flag("static_cleared") and not GameState.get_flag("ending_played"):
		await _play_ending()
	else:
		AudioManager.play_bgm(world.music_path, true)
		if player:
			player.set_movement_locked(false)
	return result

func _play_ending() -> void:
	GameState.set_flag("ending_played", true)
	AudioManager.play_bgm("res://audio/bgm/story.ogg", true)
	if player:
		player.set_movement_locked(true)
	var res: DialogueResource = load("res://data/dialogue/ending.dialogue")
	var balloon := DialogueManager.show_example_dialogue_balloon(res, "ending")
	await balloon.tree_exited
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/ui/Credits.tscn")

func _flash() -> void:
	var fl := ColorRect.new()
	fl.color = Color(1, 1, 1, 0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cl := CanvasLayer.new()
	cl.layer = 30
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	cl.add_child(fl)
	add_child(cl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 1.0, 0.18)
	tw.tween_property(fl, "color:a", 0.0, 0.22)
	await tw.finished
	cl.queue_free()

func _handle_defeat() -> void:
	AudioManager.play_bgm("res://audio/bgm/gameover.ogg", true)
	await get_tree().create_timer(2.0).timeout
	# Gentle penalty: lose half your cash, wake up back in town at full-ish HP.
	GameState.money = GameState.money / 2
	GameState.stats.hp = maxi(1, GameState.stats.max_hp / 2)
	GameState.stats.pp = GameState.stats.max_pp / 2
	change_world(load(GameState.current_world), "default")
	if player:
		player.set_movement_locked(false)

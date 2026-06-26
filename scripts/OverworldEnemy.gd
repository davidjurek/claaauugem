class_name OverworldEnemy
extends CharacterBody2D
## A roaming enemy on the map. Wanders, chases the player when near, and starts a
## battle on contact. Defeating it removes it; fleeing gives a short cooldown.

@export var troop: Array = ["lawn_slurry"]
@export var sprite_name: String = "slime_green"
@export var boss := false
@export var move_speed: float = 20.0
@export var chase := true
@export var home_flag := ""          # if set, enemy is gone once this flag is true

@onready var sprite: Sprite2D = $Sprite2D

var _player: Node2D
var _busy := false
var _cooldown := 0.0
var _dir := Vector2.ZERO
var _retarget := 0.0

func _ready() -> void:
	add_to_group("overworld_enemy")
	sprite.texture = load("res://art/enemies/%s.png" % sprite_name)
	if boss:
		sprite.scale = Vector2(2.2, 2.2)
	# gentle bob
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "position:y", sprite.position.y - 2.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position:y", sprite.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	if home_flag != "" and GameState.get_flag(home_flag):
		queue_free()

func _physics_process(delta: float) -> void:
	if _busy:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var to_player := _player.global_position - global_position
	if chase and to_player.length() < 64.0:
		_dir = to_player.normalized()
	else:
		_retarget -= delta
		if _retarget <= 0.0:
			_retarget = randf_range(0.7, 1.6)
			_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() if randf() < 0.7 else Vector2.ZERO
	velocity = _dir * move_speed
	move_and_slide()
	if _cooldown <= 0.0 and to_player.length() < 11.0:
		_trigger()

func _trigger() -> void:
	var main := get_tree().current_scene
	if _busy or main == null or not main.has_method("start_battle") or main.get("in_battle"):
		return
	_busy = true
	var result: String = await main.start_battle(troop, boss)
	if result == "win":
		if boss and home_flag != "":
			GameState.set_flag(home_flag, true)
		queue_free()
	else:
		_busy = false
		_cooldown = 1.8

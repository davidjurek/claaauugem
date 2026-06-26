class_name NPC
extends CharacterBody2D
## A townsperson. Solid obstacle + interactable. On interaction it turns to face
## the player and plays the linked dialogue. `character_index` picks one of the
## six Kenney sprites; `dialogue_path` + `dialogue_title` choose what they say.

@export var character_index: int = 0
@export var facing: String = "down"
@export_file("*.dialogue") var dialogue_path: String
@export var dialogue_title: String = "start"
@export var wander: bool = false
@export var shop_stock: Array = []      # if set, opens a shop after dialogue

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _busy := false

func _ready() -> void:
	if character_index < 0:
		sprite.visible = false        # invisible dialogue spot (e.g. a rustling bush)
	else:
		var tex: Texture2D = load("res://art/characters/char_%02d.png" % character_index)
		sprite.sprite_frames = CharacterFactory.build(tex)
		sprite.play("idle_" + facing)
	add_to_group("npc")

func interact(player: Player) -> void:
	if _busy or dialogue_path == "":
		return
	# Turn to face the player.
	var to_player := (player.global_position - global_position)
	if abs(to_player.x) > abs(to_player.y):
		facing = "right" if to_player.x > 0 else "left"
	else:
		facing = "down" if to_player.y > 0 else "up"
	if sprite.visible:
		sprite.play("idle_" + facing)

	_busy = true
	player.set_movement_locked(true)
	var res: DialogueResource = load(dialogue_path)
	var balloon := DialogueManager.show_example_dialogue_balloon(res, dialogue_title)
	await balloon.tree_exited
	if not shop_stock.is_empty():
		var shop = preload("res://scenes/ui/Shop.tscn").instantiate()
		shop.stock = shop_stock
		get_tree().current_scene.add_child(shop)
		await shop.closed
	player.set_movement_locked(false)
	_busy = false

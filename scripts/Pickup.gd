class_name Pickup
extends Area2D
## A collectible on the ground (treasure). Interact to take it; a flag stops it
## from coming back. Shows as a small sprite from the urban tilemap.

@export var item_id: String = "soda"
@export var flag: String = ""
@export var atlas := Vector2i(8, 11)   # default: mailbox-ish parcel look

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if flag != "" and GameState.get_flag(flag):
		queue_free()
		return
	var at := AtlasTexture.new()
	at.atlas = UrbanTileSet.get_tileset().get_source(0).texture
	at.region = Rect2(atlas * 16, Vector2(16, 16))
	sprite.texture = at

func interact(player: Player) -> void:
	if flag != "":
		GameState.set_flag(flag, true)
	GameState.add_item(item_id)
	var res: DialogueResource = load("res://data/dialogue/system.dialogue")
	# quick inline-ish message via the balloon
	player.set_movement_locked(true)
	var line := "%s found %s!" % [GameState.hero_name, ItemDB.name_of(item_id)]
	var balloon := DialogueManager.show_example_dialogue_balloon(_temp_resource(line), "msg")
	await balloon.tree_exited
	player.set_movement_locked(false)
	queue_free()

func _temp_resource(text: String) -> DialogueResource:
	return DialogueManager.create_resource_from_text("~ msg\nSystem: %s\n=> END" % text)

extends Node
## Game root. Loads a world, spawns the single player at a named spawn point,
## and overlays the touch controls. Scene transitions go through change_world().

const PLAYER_SCENE := preload("res://scenes/world/Player.tscn")
const TOUCH_SCENE := preload("res://scenes/ui/TouchControls.tscn")

@export var start_world: PackedScene = preload("res://scenes/world/TownSquare.tscn")

var world: GameWorld
var player: Player

func _ready() -> void:
	change_world(start_world, "default")
	add_child(TOUCH_SCENE.instantiate())

func change_world(scene: PackedScene, spawn := "default") -> void:
	if world and is_instance_valid(world):
		world.queue_free()
	world = scene.instantiate()
	add_child(world)
	# world._ready() has run (build_map + spawn points populated)
	player = PLAYER_SCENE.instantiate()
	player.position = world.spawn_points.get(spawn, Vector2.ZERO)
	world.entities.add_child(player)

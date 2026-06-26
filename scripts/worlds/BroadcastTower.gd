extends GameWorld
## Final area — the Broadcast Tower rooftop. Where the flash came from, and where
## MR. STATIC waits. Beating it triggers the ending.

const W := 22
const H := 26

func _init() -> void:
	music_path = "res://audio/bgm/rainy.ogg"

func build_map() -> void:
	# concrete rooftop boxed in brick
	fill(ground, 0, 0, W, H, Tiles.CONCRETE)
	fill(structures, 0, 0, W, 2, Tiles.BRICK_O_BODY, true)
	fill(structures, 0, H - 2, W, 2, Tiles.BRICK_O_BODY, true)
	fill(structures, 0, 0, 2, H, Tiles.BRICK_O_BODY, true)
	fill(structures, W - 2, 0, 2, H, Tiles.BRICK_O_BODY, true)
	for x in [10, 11]:
		carve(structures, x, H - 1); carve(structures, x, H - 2)

	# the antenna mast (central, decorative + solid)
	fill(structures, 10, 4, 2, 3, Tiles.LAMP if false else Tiles.BRICK_O_TOP, true)
	add_prop(Rect2i(Tiles.LAMP, Vector2i(1, 1)), 8, 6, true)
	add_prop(Rect2i(Tiles.LAMP, Vector2i(1, 1)), 13, 6, true)
	add_prop(Rect2i(Tiles.TRASHCAN, Vector2i(1, 1)), 4, 20, true)

	# the boss, dead center; defeating it sets the win flag
	add_enemy(["mr_static"], "skull", 11, 8, {"boss": true, "flag": "static_cleared", "speed": 10, "chase": true})

	add_border_walls()
	clear_solid(10, H); clear_solid(11, H)
	add_portal("res://scenes/world/WeirdWoods.tscn", "from_tower", 10, H - 1)

	set_spawn("default", 10, H - 3)
	set_spawn("from_woods", 10, H - 3)

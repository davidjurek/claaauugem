extends GameWorld
## Zone 2 — The Underpass. A grimy concrete tunnel under the highway. Tougher
## enemies, a Curbside Golem mini-boss blocking the way up, and a treasure.

const W := 24
const H := 34

func _init() -> void:
	music_path = "res://audio/bgm/dungeon.ogg"

func build_map() -> void:
	fill(ground, 0, 0, W, H, Tiles.CONCRETE)
	# darker asphalt gutter down the middle
	fill(ground, 10, 2, 4, H - 4, Tiles.ASPHALT)
	# brick border walls (2 thick)
	fill(structures, 0, 0, W, 2, Tiles.BRICK_R_BODY, true)
	fill(structures, 0, H - 2, W, 2, Tiles.BRICK_R_BODY, true)
	fill(structures, 0, 0, 2, H, Tiles.BRICK_R_BODY, true)
	fill(structures, W - 2, 0, 2, H, Tiles.BRICK_R_BODY, true)
	# internal pillars
	fill(structures, 6, 8, 2, 5, Tiles.BRICK_R_BODY, true)
	fill(structures, 16, 13, 2, 7, Tiles.BRICK_R_BODY, true)
	fill(structures, 8, 22, 5, 2, Tiles.BRICK_R_BODY, true)

	# doorways: south (entrance) & north (exit)
	for x in [11, 12]:
		carve(structures, x, H - 1); carve(structures, x, H - 2)
		carve(structures, x, 0); carve(structures, x, 1)

	# enemies
	add_enemy(["slushie"], "slime_red", 6, 18)
	add_enemy(["gnome"], "goblin", 17, 24)
	add_enemy(["slushie", "toadstool"], "slime_red", 8, 6)
	add_enemy(["gnome", "slushie"], "goblin", 18, 8)
	# mini-boss golem guards the north door
	add_enemy(["golem"], "golem", 12, 5, {"flag": "golem_down", "speed": 13, "chase": true})

	# treasure
	add_pickup("cola", 4, 4, "underpass_cola", Tiles.MAILBOX)
	add_pickup("battery", 20, 28, "underpass_batt", Tiles.TRASHCAN)

	add_border_walls()
	add_portal("res://scenes/world/MaplePark.tscn", "from_underpass", 11, H - 1)
	add_portal("res://scenes/world/WeirdWoods.tscn", "from_underpass", 12, 0, {"flag": "golem_down"})

	set_spawn("default", 11, H - 3)
	set_spawn("from_park", 11, H - 3)
	set_spawn("from_woods", 12, 2)

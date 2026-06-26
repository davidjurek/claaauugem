extends GameWorld
## Hub town: "Static Falls" town square. Roads, sidewalks, brick storefronts,
## a little pond, trees and street furniture. Player spawns in the central plaza.

const RED := {"top": Tiles.BRICK_R_TOP, "body": Tiles.BRICK_R_BODY, "band": Tiles.BRICK_R_BAND, "base": Tiles.BRICK_R_BASE}
const ORANGE := {"top": Tiles.BRICK_O_TOP, "body": Tiles.BRICK_O_BODY, "band": Tiles.BRICK_O_BAND, "base": Tiles.BRICK_O_BASE}
const NPC_SCENE := preload("res://scenes/world/NPC.tscn")
const SAVE_SCENE := preload("res://scenes/world/SavePoint.tscn")
const TOWN_DLG := "res://data/dialogue/town.dialogue"

func build_map() -> void:
	# 1. grass base
	fill(ground, 0, 0, 44, 30, Tiles.GRASS)

	# 2. horizontal road through the middle
	fill(ground, 0, 14, 44, 3, Tiles.ASPHALT)
	for x in range(0, 44, 2):
		paint(ground, x, 15, Tiles.ROAD_DASH)
	# crosswalk linking plaza to north side
	for y in range(14, 17):
		paint(ground, 21, y, Tiles.ROAD_CROSS)
		paint(ground, 22, y, Tiles.ROAD_CROSS)

	# 3. sidewalks above & below the road
	fill(ground, 0, 12, 44, 2, Tiles.CONCRETE)
	fill(ground, 0, 17, 44, 2, Tiles.CONCRETE)

	# 4. central plaza
	fill(ground, 15, 19, 14, 8, Tiles.CONCRETE)

	# 5. storefronts along the top (doors face south onto the sidewalk)
	stamp_building(4, 3, 7, 8, RED)        # Drugstore
	stamp_building(14, 4, 6, 7, ORANGE)    # Hotel
	stamp_building(25, 3, 8, 8, RED)        # Arcade
	stamp_building(36, 4, 6, 7, ORANGE)    # House

	# 6. pond, lower-left, with a grass surround already in place
	fill(ground, 3, 21, 8, 5, Tiles.WATER, true)

	# 7. props -----------------------------------------------------------------
	# trees lining the plaza & scattered on grass
	for tx in [13, 16, 27, 30]:
		add_prop(Rect2i(Tiles.TREE_GREEN, Vector2i(1, 1)), tx, 18, true)
	for p in [Vector2i(34, 22), Vector2i(38, 24), Vector2i(40, 20), Vector2i(2, 27), Vector2i(8, 28)]:
		add_prop(Rect2i(Tiles.TREE_GREEN, Vector2i(1, 1)), p.x, p.y, true)
	for p in [Vector2i(12, 26), Vector2i(31, 26)]:
		add_prop(Rect2i(Tiles.TREE_ORANGE, Vector2i(1, 1)), p.x, p.y, true)
	# bushes / hedges near storefronts
	for tx in [3, 11, 24, 33]:
		add_prop(Rect2i(Tiles.BUSH, Vector2i(1, 1)), tx, 11, false)
	# street furniture
	add_prop(Rect2i(Tiles.HYDRANT, Vector2i(1, 1)), 19, 12, true)
	add_prop(Rect2i(Tiles.MAILBOX, Vector2i(1, 1)), 24, 12, true)
	add_prop(Rect2i(Tiles.TRASHCAN, Vector2i(1, 1)), 17, 18, true)
	add_prop(Rect2i(Tiles.LAMP, Vector2i(1, 1)), 28, 18, true)

	# 8. townsfolk & save phone
	_npc(2, "pidge", 20, 22, "down")
	_npc(0, "gus", 25, 18, "down")
	_npc(5, "edna", 17, 24, "right")
	_npc(4, "kid", 30, 23, "left")
	var phone := SAVE_SCENE.instantiate()
	add_actor(phone, 18, 18)

	# a little path to the east park gate
	fill(ground, 40, 17, 4, 2, Tiles.CONCRETE)
	add_prop(Rect2i(Tiles.SIGN, Vector2i(1, 1)), 41, 16, false)

	add_border_walls()
	clear_solid(44, 17); clear_solid(44, 18)

	# 9. exits & spawn points
	add_portal("res://scenes/world/MaplePark.tscn", "from_town", 43, 18)
	set_spawn("default", 22, 23)
	set_spawn("from_north", 21, 13)
	set_spawn("from_park", 41, 18)

func _npc(idx: int, title: String, tx: int, ty: int, face: String) -> void:
	var npc := NPC_SCENE.instantiate()
	npc.character_index = idx
	npc.dialogue_path = TOWN_DLG
	npc.dialogue_title = title
	npc.facing = face
	add_actor(npc, tx, ty)

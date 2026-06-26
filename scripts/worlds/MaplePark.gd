extends GameWorld
## Zone 1 — Maple Park. A leafy park on the edge of town where the static first
## started leaking. Weak enemies, the lost-cat side quest, and the path north to
## the Underpass.

func _init() -> void:
	music_path = "res://audio/bgm/fountain.ogg"

func build_map() -> void:
	fill(ground, 0, 0, 40, 30, Tiles.GRASS)

	# winding concrete path from the west gate to the north exit
	fill(ground, 0, 14, 22, 2, Tiles.CONCRETE)
	fill(ground, 18, 2, 2, 14, Tiles.CONCRETE)
	fill(ground, 18, 14, 12, 2, Tiles.CONCRETE)

	# pond
	fill(ground, 25, 18, 9, 7, Tiles.WATER, true)

	# tree borders & clusters (props sort with the player)
	for tx in range(2, 38, 3):
		add_prop(Rect2i(Tiles.TREE_GREEN, Vector2i(1, 1)), tx, 1, true)
	for p in [Vector2i(4, 8), Vector2i(8, 20), Vector2i(11, 24), Vector2i(33, 6), Vector2i(36, 12), Vector2i(6, 26), Vector2i(30, 27)]:
		add_prop(Rect2i(Tiles.TREE_GREEN, Vector2i(1, 1)), p.x, p.y, true)
	for p in [Vector2i(13, 6), Vector2i(35, 22), Vector2i(3, 19), Vector2i(22, 27)]:
		add_prop(Rect2i(Tiles.TREE_ORANGE, Vector2i(1, 1)), p.x, p.y, true)
	for p in [Vector2i(16, 12), Vector2i(24, 9), Vector2i(10, 12)]:
		add_prop(Rect2i(Tiles.BUSH, Vector2i(1, 1)), p.x, p.y, false)
	add_prop(Rect2i(Tiles.BENCH, Vector2i(1, 1)), 21, 16, true)
	add_prop(Rect2i(Tiles.LAMP, Vector2i(1, 1)), 17, 16, true)

	# roaming enemies
	add_enemy(["lawn_slurry"], "slime_green", 8, 10)
	add_enemy(["lawn_slurry", "toadstool"], "mushroom", 26, 12)
	add_enemy(["toadstool"], "mushroom", 12, 22)
	add_enemy(["lawn_slurry", "lawn_slurry"], "slime_green", 32, 18)

	# NPC: the cat lady (lost-cat side quest)
	var npc := preload("res://scenes/world/NPC.tscn").instantiate()
	npc.character_index = 5
	npc.dialogue_path = "res://data/dialogue/park.dialogue"
	npc.dialogue_title = "catlady"
	npc.facing = "down"
	add_actor(npc, 4, 16)

	add_border_walls()
	# leave gaps for the exits
	clear_solid(-1, 14); clear_solid(-1, 15)
	clear_solid(18, -1); clear_solid(19, -1)

	# exits
	add_portal("res://scenes/world/TownSquare.tscn", "from_park", 0, 15)
	add_portal("res://scenes/world/Underpass.tscn", "from_park", 18, 1)

	set_spawn("default", 2, 15)
	set_spawn("from_town", 2, 15)
	set_spawn("from_underpass", 18, 3)

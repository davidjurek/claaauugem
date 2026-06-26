extends GameWorld
## Zone 3 — The Weird Woods. A maze of autumn trees behind the underpass, where
## the static is thick and the air hums. Ghostly enemies; the path up to the tower.

const W := 36
const H := 32

func _init() -> void:
	music_path = "res://audio/bgm/shrine.ogg"

func build_map() -> void:
	fill(ground, 0, 0, W, H, Tiles.GRASS)
	# a faint dirt path winding up
	fill(ground, 16, 0, 3, H, Tiles.ASPHALT)
	fill(ground, 4, 22, 14, 2, Tiles.ASPHALT)

	# dense tree maze (props sort with player; trunks are solid)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for ty in range(1, H - 1, 2):
		for tx in range(1, W - 1, 2):
			# keep the central path clear
			if tx >= 15 and tx <= 19:
				continue
			if ty >= 21 and ty <= 24 and tx <= 18:
				continue
			if rng.randf() < 0.42:
				var kind := Tiles.TREE_ORANGE if rng.randf() < 0.6 else Tiles.TREE_GREEN
				add_prop(Rect2i(kind, Vector2i(1, 1)), tx, ty, true)

	# eerie enemies
	add_enemy(["wraith"], "skeleton", 10, 14)
	add_enemy(["signal"], "skull", 24, 10, {"speed": 26})
	add_enemy(["wraith", "wraith"], "skeleton", 8, 26)
	add_enemy(["signal", "wraith"], "skull", 26, 24, {"speed": 24})
	add_enemy(["mimic"], "mimic", 6, 6, {"chase": false})

	add_pickup("cola", 30, 28, "woods_cola", Tiles.MAILBOX)
	add_pickup("antenna_key", 4, 4, "has_tower_key", Tiles.HYDRANT)

	# a lone shrine NPC
	var npc := preload("res://scenes/world/NPC.tscn").instantiate()
	npc.character_index = 3
	npc.dialogue_path = "res://data/dialogue/woods.dialogue"
	npc.dialogue_title = "hermit"
	npc.facing = "down"
	add_actor(npc, 20, 18)

	add_border_walls()
	clear_solid(17, H); clear_solid(18, H)   # south gap (to underpass)
	clear_solid(17, -1); clear_solid(18, -1) # north gap (to tower)

	add_portal("res://scenes/world/Underpass.tscn", "from_woods", 17, H - 1)
	add_portal("res://scenes/world/BroadcastTower.tscn", "from_woods", 17, 0, {"flag": "has_tower_key"})

	set_spawn("default", 17, H - 3)
	set_spawn("from_underpass", 17, H - 3)
	set_spawn("from_tower", 17, 2)

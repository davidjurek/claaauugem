class_name GameWorld
extends Node2D
## Base for all explorable areas. Subclasses implement build_map() using the
## paint helpers below. Terrain goes on TileMapLayers; tall props (trees, signs)
## and actors live in a y-sorted Entities node so they sort by their feet.
## Collision is generated procedurally from the `solids` set.

const TILE := 16

@onready var ground: TileMapLayer = $Ground
@onready var structures: TileMapLayer = $Structures
@onready var entities: Node2D = $Entities

var solids: Dictionary = {}          # Vector2i -> true
var map_w: int = 0
var map_h: int = 0
var spawn_points: Dictionary = {}    # name -> Vector2 (world px)
var music_path: String = "res://audio/bgm/town.ogg"   # worlds override

func _ready() -> void:
	ground.tile_set = UrbanTileSet.get_tileset()
	structures.tile_set = UrbanTileSet.get_tileset()
	build_map()
	_generate_collision()

# --- override in subclasses ---
func build_map() -> void:
	pass

# --- authoring helpers -------------------------------------------------------
func tile_to_world(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE + TILE / 2.0, ty * TILE + TILE / 2.0)

func paint(layer: TileMapLayer, tx: int, ty: int, atlas: Vector2i) -> void:
	layer.set_cell(Vector2i(tx, ty), 0, atlas)

func fill(layer: TileMapLayer, tx: int, ty: int, w: int, h: int, atlas: Vector2i, solid := false) -> void:
	for y in range(ty, ty + h):
		for x in range(tx, tx + w):
			layer.set_cell(Vector2i(x, y), 0, atlas)
			if solid:
				solids[Vector2i(x, y)] = true
	map_w = max(map_w, tx + w)
	map_h = max(map_h, ty + h)

func solid(tx: int, ty: int) -> void:
	solids[Vector2i(tx, ty)] = true

func clear_solid(tx: int, ty: int) -> void:
	solids.erase(Vector2i(tx, ty))

## Place a multi-tile prop (e.g. a tree) as a single y-sorted sprite whose
## origin sits at its base so it sorts correctly against the player.
func add_prop(atlas_rect: Rect2i, base_tx: int, base_ty: int, solid_base := true) -> Sprite2D:
	var spr := Sprite2D.new()
	var at := AtlasTexture.new()
	at.atlas = UrbanTileSet.get_tileset().get_source(0).texture
	at.region = Rect2(atlas_rect.position * TILE, atlas_rect.size * TILE)
	spr.texture = at
	spr.centered = false
	# base_tx/base_ty is the bottom-left tile; position sprite so its bottom rests there
	var px := base_tx * TILE
	var py := (base_ty + 1) * TILE - atlas_rect.size.y * TILE
	spr.position = Vector2(px, py)
	# y-sort uses the node origin; nudge so it sorts by the base row
	spr.y_sort_enabled = true
	entities.add_child(spr)
	if solid_base:
		solids[Vector2i(base_tx, base_ty)] = true
	return spr

func add_actor(node: Node2D, tx: int, ty: int) -> void:
	node.position = tile_to_world(tx, ty)
	entities.add_child(node)

const PORTAL_SCENE := preload("res://scenes/world/Portal.tscn")

func add_portal(target_scene: String, target_spawn: String, tx: int, ty: int, opts := {}) -> void:
	var p := PORTAL_SCENE.instantiate()
	p.target_scene = target_scene
	p.target_spawn = target_spawn
	p.require_flag = opts.get("flag", "")
	p.position = tile_to_world(tx, ty)
	add_child(p)

const ENEMY_SCENE := preload("res://scenes/world/OverworldEnemy.tscn")

func add_enemy(troop: Array, sprite: String, tx: int, ty: int, opts := {}) -> void:
	var e := ENEMY_SCENE.instantiate()
	e.troop = troop
	e.sprite_name = sprite
	e.boss = opts.get("boss", false)
	e.chase = opts.get("chase", true)
	e.move_speed = opts.get("speed", 20.0)
	e.home_flag = opts.get("flag", "")
	add_actor(e, tx, ty)

func set_spawn(name: String, tx: int, ty: int) -> void:
	spawn_points[name] = tile_to_world(tx, ty)

## Stamp a rectangular building. `pal` keys: top, body, band, base.
## Whole footprint is solid except the door tile (one tile of walkable threshold
## is left so the player can stand in front). Returns the door's world position.
func stamp_building(tx: int, ty: int, w: int, h: int, pal: Dictionary, door_dx := -1) -> Vector2:
	if door_dx < 0:
		door_dx = w / 2
	for y in h:
		for x in w:
			var atlas: Vector2i = pal.body
			if y == 0:
				atlas = pal.top
			elif y == h - 1:
				atlas = pal.base
			elif y == h - 2 and h >= 4:
				atlas = pal.band
			paint(structures, tx + x, ty + y, atlas)
			solids[Vector2i(tx + x, ty + y)] = true
	# door on the bottom wall row
	paint(structures, tx + door_dx, ty + h - 1, pal.get("door", Tiles.DOOR_WOOD))
	# windows on the body
	for x in range(1, w - 1, 2):
		if x != door_dx:
			paint(structures, tx + x, ty + 1, pal.get("window", Tiles.WINDOW))
	map_w = max(map_w, tx + w)
	map_h = max(map_h, ty + h)
	return tile_to_world(tx + door_dx, ty + h)

# --- collision ---------------------------------------------------------------
func _generate_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "Solids"
	# Greedy-merge solid cells into horizontal runs to keep shape count low.
	var done: Dictionary = {}
	for cell in solids.keys():
		if done.has(cell):
			continue
		var run := 1
		while solids.has(Vector2i(cell.x + run, cell.y)) and not done.has(Vector2i(cell.x + run, cell.y)):
			run += 1
		for i in run:
			done[Vector2i(cell.x + i, cell.y)] = true
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(run * TILE, TILE)
		cs.shape = rect
		cs.position = Vector2(cell.x * TILE + run * TILE / 2.0, cell.y * TILE + TILE / 2.0)
		body.add_child(cs)
	add_child(body)

# Walls around the outside so the player can't leave the painted area.
func add_border_walls() -> void:
	for x in range(-1, map_w + 1):
		solids[Vector2i(x, -1)] = true
		solids[Vector2i(x, map_h)] = true
	for y in range(-1, map_h + 1):
		solids[Vector2i(-1, y)] = true
		solids[Vector2i(map_w, y)] = true

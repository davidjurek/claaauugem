class_name UrbanTileSet
extends RefCounted
## Builds (once) a Godot TileSet from the Kenney RPG Urban tilemap.
## 27x18 grid of 16x16 tiles, source id 0. Collision is handled procedurally by
## the world builder (a StaticBody is generated from the solid map), so the
## TileSet itself carries no per-tile collision — keeps tile authoring trivial.

const TEX_PATH := "res://art/tilesets/urban_tilemap.png"
const COLS := 27
const ROWS := 18
const TILE := 16

static var _cached: TileSet

static func get_tileset() -> TileSet:
	if _cached:
		return _cached
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load(TEX_PATH)
	src.texture_region_size = Vector2i(TILE, TILE)
	for y in ROWS:
		for x in COLS:
			src.create_tile(Vector2i(x, y))
	ts.add_source(src, 0)
	_cached = ts
	return ts

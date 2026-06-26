class_name CharacterFactory
extends RefCounted
## Builds a SpriteFrames resource from a Kenney RPG Urban character sheet.
## Sheet layout: 64x48 px, 16x16 cells, columns = [left, down, up, right],
## rows = 3 walk-cycle frames. We expose per-direction "walk" and "idle" anims.

const CELL := 16
const COL := {"left": 0, "down": 1, "up": 2, "right": 3}
# Walk plays as a 4-step ping-pong: stand, stepA, stand, stepB (rows 0,1,0,2).
const WALK_ROWS := [0, 1, 0, 2]
const IDLE_ROW := 0

static func build(sheet: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for dir in COL.keys():
		var col: int = COL[dir]
		# idle
		var idle_name: String = "idle_" + str(dir)
		sf.add_animation(idle_name)
		sf.set_animation_loop(idle_name, true)
		sf.set_animation_speed(idle_name, 1.0)
		sf.add_frame(idle_name, _atlas(sheet, col, IDLE_ROW))
		# walk
		var walk_name: String = "walk_" + str(dir)
		sf.add_animation(walk_name)
		sf.set_animation_loop(walk_name, true)
		sf.set_animation_speed(walk_name, 8.0)
		for r in WALK_ROWS:
			sf.add_frame(walk_name, _atlas(sheet, col, r))
	return sf

static func _atlas(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return at

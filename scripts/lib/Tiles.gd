class_name Tiles
extends RefCounted
## Named atlas coordinates into the Kenney RPG Urban tilemap (col, row).
## Verified against a labeled render of the sheet.

# --- ground fills (seamless) ---
const GRASS := Vector2i(1, 1)
const CONCRETE := Vector2i(13, 1)      # light lavender-grey sidewalk/plaza
const ASPHALT := Vector2i(4, 17)       # darker road surface
const ROAD_CROSS := Vector2i(4, 16)    # crosswalk stripes
const ROAD_DASH := Vector2i(1, 16)     # centre lane dash
const WATER := Vector2i(9, 6)

# --- red brick building (9-slice rows 0..3) ---
const BRICK_R_TOP := Vector2i(18, 0)   # roofline / cornice
const BRICK_R_BODY := Vector2i(18, 2)  # plain wall
const BRICK_R_BAND := Vector2i(18, 1)  # floor divider band
const BRICK_R_BASE := Vector2i(18, 3)  # base trim

# --- orange brick building (rows 4..7) ---
const BRICK_O_TOP := Vector2i(18, 4)
const BRICK_O_BODY := Vector2i(18, 6)
const BRICK_O_BAND := Vector2i(18, 5)
const BRICK_O_BASE := Vector2i(18, 7)

# --- facade details ---
const DOOR_WOOD := Vector2i(13, 10)
const DOOR_GLASS := Vector2i(15, 10)
const DOOR_FANCY := Vector2i(13, 12)
const WINDOW := Vector2i(12, 9)
const WINDOW_WIDE := Vector2i(8, 13)
const WINDOW_SHOP := Vector2i(9, 14)

# --- props (placed as y-sorted sprites; values are atlas col,row) ---
const TREE_GREEN := Vector2i(22, 10)
const TREE_ORANGE := Vector2i(22, 13)
const BUSH := Vector2i(22, 8)
const HEDGE := Vector2i(8, 12)
const HYDRANT := Vector2i(8, 9)
const MAILBOX := Vector2i(8, 11)
const TRASHCAN := Vector2i(8, 10)
const BENCH := Vector2i(3, 8)
const LAMP := Vector2i(1, 6)
const SIGN := Vector2i(4, 5)
const CAR_YELLOW := Vector2i(16, 14)
const CAR_RED := Vector2i(16, 16)
const CAR_GREEN := Vector2i(21, 14)

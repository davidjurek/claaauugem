extends Node2D
## Dev-only: instantiate a world and frame the whole map for a verification shot.
## Run: godot --path . scenes/dev/MapPreview.tscn -- --shot out.png 1.0

@export var world_scene: PackedScene = preload("res://scenes/world/TownSquare.tscn")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var wi := args.find("--world")
	if wi != -1 and wi + 1 < args.size():
		world_scene = load(args[wi + 1])
	var w: GameWorld = world_scene.instantiate()
	add_child(w)
	var cam := Camera2D.new()
	add_child(cam)
	var mw := w.map_w * 16
	var mh := w.map_h * 16
	cam.position = Vector2(mw / 2.0, mh / 2.0)
	var z: float = min(480.0 / mw, 270.0 / mh)
	cam.zoom = Vector2(z, z)
	cam.make_current()

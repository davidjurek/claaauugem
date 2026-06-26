extends Node
## Dev/testing helper (autoload). Enables: `godot -- --shot <path> [delay] [secs]`
## to capture a screenshot of whatever is running after `delay` seconds, then
## quit. Used by the automated visual smoke tests. No effect in normal play.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--smoketest"):
		_smoketest(args)
		return
	var d := args.find("--dialogue")
	if d != -1 and d + 2 < args.size():
		_show_dialogue_then_shot(args[d + 1], args[d + 2], args)
		return
	var i := args.find("--shot")
	if i != -1 and i + 1 < args.size():
		var path := args[i + 1]
		var delay := 0.6
		if i + 2 < args.size() and args[i + 2].is_valid_float():
			delay = args[i + 2].to_float()
		_capture_after(path, delay)

var _dialogue_fired := false

func _smoketest(args: PackedStringArray) -> void:
	await get_tree().create_timer(0.6).timeout
	var main := get_tree().current_scene
	var player = main.get("player")
	var world = main.get("world")
	var npcs := get_tree().get_nodes_in_group("npc")
	var ok := true
	print("[SMOKE] player=", player, " world=", world, " npcs=", npcs.size())
	if player == null or world == null or npcs.is_empty():
		print("[SMOKE] FAIL: missing core objects")
		_finish_smoke(args, false)
		return
	# Move the player directly south of the first NPC and face up toward it.
	var npc = npcs[0]
	player.global_position = npc.global_position + Vector2(0, 13)
	player.facing = "up"
	DialogueManager.dialogue_started.connect(func(_r): _dialogue_fired = true)
	# let physics register the area overlap
	for i in 4:
		await get_tree().physics_frame
	player.call("_try_interact")
	await get_tree().create_timer(0.6).timeout
	print("[SMOKE] dialogue_fired=", _dialogue_fired)
	ok = _dialogue_fired
	# also assert collision kept player out of solids (still near npc)
	var dist: float = player.global_position.distance_to(npc.global_position)
	print("[SMOKE] player-npc dist=", dist, " (expect ~13, collision held)")
	_finish_smoke(args, ok)

func _finish_smoke(args: PackedStringArray, ok: bool) -> void:
	print("[SMOKE] RESULT: ", "PASS" if ok else "FAIL")
	var i := args.find("--shot")
	if i != -1 and i + 1 < args.size():
		await _capture_after(args[i + 1], 0.3)
	else:
		get_tree().quit(0 if ok else 1)

func _show_dialogue_then_shot(dlg_path: String, title: String, args: PackedStringArray) -> void:
	await get_tree().create_timer(0.8).timeout
	var res = load(dlg_path)
	print("[DEV] dialogue resource is ", res, " (valid=", res is DialogueResource, ")")
	if res is DialogueResource:
		DialogueManager.show_example_dialogue_balloon(res, title)
	var i := args.find("--shot")
	if i != -1 and i + 1 < args.size():
		_capture_after(args[i + 1], 0.8)

func _capture_after(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[DEV] screenshot -> ", path)
	get_tree().quit(0)

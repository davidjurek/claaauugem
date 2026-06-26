extends Control
## Temporary Milestone-0 boot screen.
## Confirms the engine, rendering, and project config run end-to-end.
## Will be replaced by the real Title screen in Milestone 1.

@onready var status_label: Label = $Center/VBox/Status

func _ready() -> void:
	print("[BOOT] PSYCHO SUBURBIA booting...")
	print("[BOOT] Godot ", Engine.get_version_info().string)
	print("[BOOT] Viewport ", get_viewport().get_visible_rect().size)
	if status_label:
		status_label.text = "engine ok · %s" % Engine.get_version_info().string
	# Auto-quit when run headless in CI/smoke-test mode.
	if DisplayServer.get_name() == "headless" or OS.has_feature("smoke_test"):
		print("[BOOT] headless smoke test — quitting cleanly")
		await get_tree().create_timer(0.1).timeout
		get_tree().quit(0)
		return
	# Screenshot-capture mode: run windowed with `-- --shot <path>`, grab a frame, quit.
	var args := OS.get_cmdline_user_args()
	var idx := args.find("--shot")
	if idx != -1 and idx + 1 < args.size():
		var path := args[idx + 1]
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(path)
		print("[BOOT] screenshot saved -> ", path)
		get_tree().quit(0)

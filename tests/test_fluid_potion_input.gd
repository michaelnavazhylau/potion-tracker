extends SceneTree


var _press_count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var potion_scene: PackedScene = load("res://FluidPotion.tscn")
	var potion: FluidPotion = potion_scene.instantiate()
	root.add_child(potion)
	await process_frame

	potion.potion_pressed.connect(_on_potion_pressed)

	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	potion._on_hit_area_input_event(root, touch, 0)

	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	potion._on_hit_area_input_event(root, emulated_mouse, 0)

	if _press_count != 1:
		push_error(
			"A touch plus its emulated mouse event must emit exactly once."
		)
		quit(1)
		return

	var browser_mouse := InputEventMouseButton.new()
	browser_mouse.button_index = MOUSE_BUTTON_LEFT
	browser_mouse.pressed = true
	browser_mouse.device = InputEvent.DEVICE_ID_MOUSE
	potion._on_hit_area_input_event(root, browser_mouse, 0)

	if _press_count != 1:
		push_error(
			"A mouse-like browser follow-up after touch must be ignored."
		)
		quit(1)
		return

	potion._suppress_mouse_until_msec = 0
	var physical_mouse := InputEventMouseButton.new()
	physical_mouse.button_index = MOUSE_BUTTON_LEFT
	physical_mouse.pressed = true
	physical_mouse.device = InputEvent.DEVICE_ID_MOUSE
	potion._on_hit_area_input_event(root, physical_mouse, 0)

	if _press_count != 2:
		push_error("A physical left mouse press must still emit once.")
		quit(1)
		return

	var emulated_mouse_fallback := InputEventMouseButton.new()
	emulated_mouse_fallback.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse_fallback.pressed = true
	emulated_mouse_fallback.device = InputEvent.DEVICE_ID_EMULATION
	potion._on_hit_area_input_event(root, emulated_mouse_fallback, 0)

	if _press_count != 3:
		push_error(
			"An emulated mouse press without a preceding touch must work."
		)
		quit(1)
		return

	potion.queue_free()
	await process_frame

	var game_scene: PackedScene = load("res://main_scene.tscn")
	var game: Node2D = game_scene.instantiate()
	root.add_child(game)
	await process_frame

	var source: FluidPotion = game.get_node("Potion1")
	var destination: FluidPotion = game.get_node("Potion4")
	_emit_mobile_tap(source)

	if not source.potion_selected:
		push_error("A mobile tap must leave the source potion selected.")
		quit(1)
		return

	_emit_mobile_tap(destination)

	if source.potion_stack.size != 3 or destination.potion_stack.size != 1:
		push_error("Two mobile taps must select and perform a valid pour.")
		quit(1)
		return

	print(
		"PASS: touch is deduplicated, mobile selection pours, and mouse works."
	)
	quit(0)


func _on_potion_pressed(_potion: FluidPotion) -> void:
	_press_count += 1


func _emit_mobile_tap(potion: FluidPotion) -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	potion._on_hit_area_input_event(root, touch, 0)

	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	potion._on_hit_area_input_event(root, emulated_mouse, 0)

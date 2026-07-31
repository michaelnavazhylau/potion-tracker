extends SceneTree


const BOTTLE_CENTER := Vector2(90.0, 135.0)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_scene: PackedScene = load("res://main_scene.tscn")
	var game: Node2D = game_scene.instantiate()
	root.add_child(game)
	await process_frame

	var source: FluidPotion = game.get_node("Potion1")
	var destination: FluidPotion = game.get_node("Potion4")

	var outside_touch := InputEventScreenTouch.new()
	outside_touch.pressed = true
	outside_touch.position = Vector2.ZERO
	game._unhandled_input(outside_touch)
	if source.potion_selected:
		_fail("A touch outside every bottle must not select a potion.")
		return

	_emit_touch(game, source)
	if not source.potion_selected:
		_fail("A routed touch must select its transformed bottle.")
		return

	_emit_touch(game, destination)
	if source.potion_stack.size != 3 or destination.potion_stack.size != 1:
		_fail("Two routed touches must perform a valid pour.")
		return
	while game._pour_in_progress:
		await process_frame

	game._on_reset_pressed()
	game._suppress_mouse_until_msec = 0
	_emit_mouse_press(game, source)
	if not source.potion_selected:
		_fail("A physical mouse press must use the same direct hit test.")
		return

	game._clear_selection()
	game._suppress_mouse_until_msec = Time.get_ticks_msec() + 500
	_emit_mouse_press(game, source)
	if source.potion_selected:
		_fail("A mouse follow-up immediately after touch must be suppressed.")
		return

	game._layout_potions(Vector2(720.0, 1280.0), Vector4.ZERO)
	game._suppress_mouse_until_msec = 0
	_emit_touch(game, source)
	if not source.potion_selected:
		_fail("Direct touch hit-testing must respect scaled layouts.")
		return

	print(
		"PASS: direct touch and mouse hit-testing works without physics picking."
	)
	quit(0)


func _emit_touch(game: Node2D, potion: FluidPotion) -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = _potion_center_in_viewport(potion)
	game._unhandled_input(touch)


func _emit_mouse_press(game: Node2D, potion: FluidPotion) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = _potion_center_in_viewport(potion)
	game._unhandled_input(mouse)


func _potion_center_in_viewport(potion: FluidPotion) -> Vector2:
	return potion.get_global_transform_with_canvas() * BOTTLE_CENTER


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

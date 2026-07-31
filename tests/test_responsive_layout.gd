extends SceneTree


const EPSILON := 0.01


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_scene: PackedScene = load("res://main_scene.tscn")
	var game: Node2D = game_scene.instantiate()
	root.add_child(game)
	await process_frame

	var potions: Array[FluidPotion] = [
		game.get_node("Potion1"),
		game.get_node("Potion2"),
		game.get_node("Potion3"),
		game.get_node("Potion4"),
	]
	var no_safe_insets := Vector4.ZERO

	game._layout_potions(Vector2(720.0, 1280.0), no_safe_insets)
	if not _is_portrait_grid(potions):
		_fail("Portrait layout must arrange potions in a centered 2x2 grid.")
		return
	if not _potions_fit_bounds(
		potions,
		Rect2(36.0, 128.0, 648.0, 1116.0)
	):
		_fail("Portrait potions must remain inside the constrained board.")
		return

	game._layout_potions(Vector2(1280.0, 720.0), no_safe_insets)
	if not _is_landscape_row(potions):
		_fail("Landscape layout must arrange potions in one centered row.")
		return
	if not _potions_fit_bounds(
		potions,
		Rect2(36.0, 128.0, 1208.0, 556.0)
	):
		_fail("Landscape potions must remain inside the constrained board.")
		return

	game._on_difficulty_pressed(PuzzleGenerator.Difficulty.HARD)
	game._on_new_puzzle_pressed()
	potions.assign(game.potions)
	game._layout_potions(Vector2(720.0, 1280.0), no_safe_insets)
	if potions.size() != 9 or not _potions_do_not_overlap(potions):
		_fail("Hard portrait layout must arrange nine non-overlapping potions.")
		return
	if not _potions_fit_bounds(
		potions,
		Rect2(36.0, 174.0, 648.0, 1070.0)
	):
		_fail("Hard portrait potions must remain inside the board.")
		return

	game._layout_potions(Vector2(1280.0, 720.0), no_safe_insets)
	if not _potions_do_not_overlap(potions):
		_fail("Hard landscape layout must not overlap potions.")
		return
	if not _potions_fit_bounds(
		potions,
		Rect2(36.0, 174.0, 1208.0, 510.0)
	):
		_fail("Hard landscape potions must remain inside the board.")
		return

	var safe_insets := Vector4(20.0, 30.0, 40.0, 50.0)
	game._layout_status(Vector2(720.0, 1280.0), safe_insets)
	var status_margin: MarginContainer = game.get_node("UI/StatusMargin")
	if not is_equal_approx(status_margin.offset_left, 56.0):
		_fail("Status panel must respect the left safe area.")
		return
	if not is_equal_approx(status_margin.offset_top, 54.0):
		_fail("Status panel must respect the top safe area.")
		return
	if not is_equal_approx(status_margin.offset_right, -76.0):
		_fail("Status panel must respect the right safe area.")
		return
	if not is_equal_approx(status_margin.offset_bottom, 224.0):
		_fail("Mobile status panel must make room for larger touch controls.")
		return

	game._apply_responsive_controls(Vector2(720.0, 1280.0))
	if not _controls_match_mobile_size(game):
		_fail("Mobile controls must use readable text and large touch targets.")
		return

	game._apply_responsive_controls(Vector2(390.0, 844.0))
	game._layout_status(Vector2(390.0, 844.0), no_safe_insets)
	if not _controls_fit_compact_width(game, 390.0):
		_fail("Compact mobile controls must scale without clipping.")
		return

	game._apply_responsive_controls(Vector2(1280.0, 720.0))
	if not _controls_match_desktop_size(game):
		_fail("Desktop controls must return to their compact sizing.")
		return

	var touch_shape: RectangleShape2D = potions[0].get_node(
		"HitArea/CollisionShape2D"
	).shape
	if touch_shape.size != Vector2(204.0, 294.0):
		_fail("Potion touch target must include the 12px hit slop.")
		return

	print("PASS: responsive potion layouts and safe margins are valid.")
	quit(0)


func _is_portrait_grid(potions: Array[FluidPotion]) -> bool:
	return (
		absf(potions[0].position.y - potions[1].position.y) < EPSILON
		and absf(potions[2].position.y - potions[3].position.y) < EPSILON
		and potions[2].position.y > potions[0].position.y
		and absf(potions[0].position.x - potions[2].position.x) < EPSILON
		and absf(potions[1].position.x - potions[3].position.x) < EPSILON
	)


func _is_landscape_row(potions: Array[FluidPotion]) -> bool:
	for index in range(1, potions.size()):
		if absf(potions[index].position.y - potions[0].position.y) >= EPSILON:
			return false
		if potions[index].position.x <= potions[index - 1].position.x:
			return false
	return true


func _potions_fit_bounds(
	potions: Array[FluidPotion],
	bounds: Rect2
) -> bool:
	for potion in potions:
		var size := Vector2(180.0, 270.0) * potion.scale
		var potion_rect := Rect2(potion.position, size)
		if not bounds.encloses(potion_rect):
			return false
		if potion.scale.x < 0.50 or potion.scale.x > 1.0:
			return false
	return true


func _controls_match_mobile_size(game: Node2D) -> bool:
	for button: Button in game.control_buttons:
		if button.custom_minimum_size.y < 72.0:
			return false
		if button.get_theme_font_size("font_size") < 24:
			return false
	return game.status_label.get_theme_font_size("font_size") >= 26


func _controls_match_desktop_size(game: Node2D) -> bool:
	for button: Button in game.control_buttons:
		if not is_equal_approx(button.custom_minimum_size.y, 38.0):
			return false
		if button.get_theme_font_size("font_size") != 18:
			return false
	return game.status_label.get_theme_font_size("font_size") == 22


func _controls_fit_compact_width(
	game: Node2D,
	viewport_width: float
) -> bool:
	var controls_width := 8.0 * float(game.control_buttons.size() - 1)
	for button: Button in game.control_buttons:
		controls_width += button.custom_minimum_size.x
		if button.custom_minimum_size.y < 44.0:
			return false
		if button.get_theme_font_size("font_size") < 16:
			return false

	var available_width := viewport_width - 72.0 - 36.0
	return controls_width <= available_width + EPSILON


func _potions_do_not_overlap(potions: Array[FluidPotion]) -> bool:
	for first_index in range(potions.size()):
		var first := potions[first_index]
		var first_rect := Rect2(
			first.position,
			Vector2(180.0, 270.0) * first.scale
		)
		for second_index in range(first_index + 1, potions.size()):
			var second := potions[second_index]
			var second_rect := Rect2(
				second.position,
				Vector2(180.0, 270.0) * second.scale
			)
			if first_rect.intersects(second_rect):
				return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

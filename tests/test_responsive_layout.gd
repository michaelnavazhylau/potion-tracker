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
		if potion.scale.x < 0.70 or potion.scale.x > 1.0:
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

extends SceneTree


const MAIN_SCENE := preload("res://main_scene.tscn")
const BOTTLE_CENTER := Vector2(90.0, 135.0)
const SOLUTION := [
	[0, 3],
	[2, 0],
	[1, 2],
	[1, 3],
	[0, 1],
	[2, 0],
	[2, 3],
	[1, 2],
	[0, 1],
	[0, 3],
]


var game: Node2D
var cursor: Polygon2D


func _initialize() -> void:
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	call_deferred("_run_solution")


func _run_solution() -> void:
	await process_frame
	_create_demo_cursor()
	await create_timer(0.8).timeout

	var potions: Array = game.get("potions")

	for move: Array in SOLUTION:
		await _click_potion(potions[move[0]])
		await create_timer(0.16).timeout
		await _click_potion(potions[move[1]])

		while game.get("_pour_in_progress"):
			await process_frame

		await create_timer(0.24).timeout

	assert(game.call("_is_puzzle_solved"), (
		"Recorded demo solution did not solve the puzzle."
	))
	await create_timer(1.4).timeout
	quit()


func _create_demo_cursor() -> void:
	cursor = Polygon2D.new()
	cursor.z_index = 20
	cursor.color = Color(1.0, 0.92, 0.35, 1.0)
	cursor.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-9.0, 24.0),
		Vector2(-2.0, 21.0),
		Vector2(4.0, 35.0),
		Vector2(11.0, 32.0),
		Vector2(5.0, 18.0),
		Vector2(14.0, 16.0),
	])
	cursor.position = Vector2(0.0, -220.0)
	game.add_child(cursor)


func _click_potion(potion: FluidPotion) -> void:
	var target_position := potion.position + BOTTLE_CENTER
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_SINE)
	move_tween.set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(
		cursor,
		"position",
		target_position,
		0.24
	)
	await move_tween.finished

	var original_scale := cursor.scale
	var click_tween := create_tween()
	click_tween.tween_property(
		cursor,
		"scale",
		Vector2(0.78, 0.78),
		0.06
	)
	click_tween.tween_property(
		cursor,
		"scale",
		original_scale,
		0.08
	)

	potion.potion_pressed.emit(potion)
	await click_tween.finished

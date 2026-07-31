extends SceneTree


const GENERATOR := preload("res://PuzzleGenerator.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for difficulty in [
		GENERATOR.Difficulty.EASY,
		GENERATOR.Difficulty.MEDIUM,
		GENERATOR.Difficulty.HARD,
	]:
		for seed_value in range(8):
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 + difficulty * 100 + seed_value
			var generated: Dictionary = GENERATOR.generate(difficulty, rng)
			if not _validate_generated_puzzle(difficulty, generated):
				return

	var game_scene: PackedScene = load("res://main_scene.tscn")
	var game: Node2D = game_scene.instantiate()
	root.add_child(game)
	await process_frame

	var original: Array = _capture(game)
	var source: FluidPotion = game.potions[0]
	var destination: FluidPotion = game.potions[3]
	if not source.pour(destination):
		_fail("The reset test requires the default puzzle's first pour.")
		return
	game._on_reset_pressed()
	if _capture(game) != original:
		_fail("Reset must restore the current puzzle's starting state.")
		return

	game._on_difficulty_pressed(GENERATOR.Difficulty.MEDIUM)
	game._on_new_puzzle_pressed()
	if game.potions.size() != 7:
		_fail("Medium must generate five colors and two empty bottles.")
		return

	game._on_difficulty_pressed(GENERATOR.Difficulty.HARD)
	game._on_new_puzzle_pressed()
	if game.potions.size() != 9:
		_fail("Hard must generate seven colors and two empty bottles.")
		return

	print("PASS: generated puzzles are solvable and reset/new controls work.")
	quit(0)


func _validate_generated_puzzle(
	difficulty: int,
	generated: Dictionary
) -> bool:
	var config: Dictionary = GENERATOR.CONFIGS[difficulty]
	var bottles: Array = generated["bottles"]
	var expected_bottle_count: int = (
		config["color_count"] + config["empty_count"]
	)
	if bottles.size() != expected_bottle_count:
		_fail("Generated puzzle has the wrong bottle count.")
		return false

	var color_counts: Array[int] = []
	color_counts.resize(config["color_count"])
	color_counts.fill(0)
	var stacks: Array[PotionStack] = []

	for bottle: Array in bottles:
		var typed_colors: Array[PotionColors.PotionColor] = []
		for color: int in bottle:
			if color < 0 or color >= config["color_count"]:
				_fail("Generated puzzle contains an out-of-range color.")
				return false
			color_counts[color] += 1
			typed_colors.append(color as PotionColors.PotionColor)

		var stack := PotionStack.new(FluidPotion.CAPACITY)
		stack.load_colors(typed_colors)
		stacks.append(stack)

	for count: int in color_counts:
		if count != FluidPotion.CAPACITY:
			_fail("Every generated color must occur exactly four times.")
			return false

	var move_index := 0
	for move: Array in generated["solution"]:
		if stacks[move[0]].transfer_to(stacks[move[1]]) <= 0:
			_fail(
				"A generated solution contains an illegal pour at move %d: %s in %s."
				% [move_index, move, bottles]
			)
			return false
		move_index += 1

	for stack: PotionStack in stacks:
		if stack.is_empty:
			continue
		if not stack.is_full:
			_fail("Generated solution left a partially filled bottle.")
			return false
		var expected_color := stack.get_color_at(0)
		for index in range(1, stack.size):
			if stack.get_color_at(index) != expected_color:
				_fail("Generated solution left a mixed bottle.")
				return false

	return true


func _capture(game: Node2D) -> Array:
	var bottles: Array = []
	for potion: FluidPotion in game.potions:
		bottles.append(potion.potion_stack.get_colors())
	return bottles


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

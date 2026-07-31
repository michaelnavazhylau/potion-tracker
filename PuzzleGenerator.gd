extends RefCounted

class_name PuzzleGenerator


enum Difficulty {
	EASY,
	MEDIUM,
	HARD,
}


const CAPACITY := FluidPotion.CAPACITY
const CONFIGS := {
	Difficulty.EASY: {
		"name": "Easy",
		"color_count": 3,
		"empty_count": 1,
		"scramble_steps": 12,
	},
	Difficulty.MEDIUM: {
		"name": "Medium",
		"color_count": 5,
		"empty_count": 2,
		"scramble_steps": 28,
	},
	Difficulty.HARD: {
		"name": "Hard",
		"color_count": 7,
		"empty_count": 2,
		"scramble_steps": 48,
	},
}


static func get_difficulty_name(difficulty: Difficulty) -> String:
	return CONFIGS[difficulty]["name"]


static func generate(
	difficulty: Difficulty,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var random := rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()

	var config: Dictionary = CONFIGS[difficulty]
	var best_result := {}
	var best_mixed_count := -1

	# A reverse scramble starts with a solved board. Every scramble move is
	# chosen so its inverse is a legal in-game pour, giving every generated
	# puzzle a known solution without an expensive search.
	for generation_attempt in range(12):
		var result := _generate_candidate(config, random)
		var mixed_count := _count_mixed_bottles(result["bottles"])
		if mixed_count > best_mixed_count:
			best_mixed_count = mixed_count
			best_result = result
		if mixed_count >= mini(3, config["color_count"]):
			return result

	return best_result


static func _generate_candidate(
	config: Dictionary,
	rng: RandomNumberGenerator
) -> Dictionary:
	var bottles: Array = []
	for color_index in range(config["color_count"]):
		var bottle: Array[PotionColors.PotionColor] = []
		for layer in range(CAPACITY):
			bottle.append(color_index as PotionColors.PotionColor)
		bottles.append(bottle)
	for empty_index in range(config["empty_count"]):
		bottles.append([] as Array[PotionColors.PotionColor])

	var inverse_moves: Array = []
	var last_source := -1
	var last_destination := -1

	for step in range(config["scramble_steps"]):
		var candidates := _find_reverse_scramble_moves(
			bottles,
			last_source,
			last_destination
		)
		if candidates.is_empty():
			break

		var move: Array = candidates[rng.randi_range(
			0,
			candidates.size() - 1
		)]
		var source: Array = bottles[move[0]]
		var destination: Array = bottles[move[1]]
		var amount: int = rng.randi_range(1, move[2])

		for layer in range(amount):
			destination.append(source.pop_back())

		inverse_moves.append([move[1], move[0]])
		last_source = move[0]
		last_destination = move[1]

	inverse_moves.reverse()
	return {
		"bottles": bottles,
		"solution": inverse_moves,
	}


static func _find_reverse_scramble_moves(
	bottles: Array,
	last_source: int,
	last_destination: int
) -> Array:
	var candidates: Array = []

	for source_index in range(bottles.size()):
		var source: Array = bottles[source_index]
		if source.is_empty():
			continue

		var source_color: int = source.back()
		var source_run_size := 1
		for layer in range(source.size() - 2, -1, -1):
			if source[layer] != source_color:
				break
			source_run_size += 1
		# If a mixed bottle exposed a different color, the inverse pour could
		# not return to it. Leave at least one layer of its current top color.
		var reversible_amount := source_run_size
		if source_run_size < source.size():
			reversible_amount -= 1
		if reversible_amount <= 0:
			continue

		for destination_index in range(bottles.size()):
			if destination_index == source_index:
				continue
			if (
				source_index == last_destination
				and destination_index == last_source
			):
				continue

			var destination: Array = bottles[destination_index]
			var empty_volume: int = CAPACITY - destination.size()
			if empty_volume <= 0:
				continue
			if (
				not destination.is_empty()
				and destination.back() == source_color
			):
				continue

			candidates.append([
				source_index,
				destination_index,
				mini(reversible_amount, empty_volume),
			])

	return candidates


static func _count_mixed_bottles(bottles: Array) -> int:
	var mixed_count := 0
	for bottle: Array in bottles:
		if bottle.size() < 2:
			continue
		var first_color: int = bottle.front()
		for color: int in bottle:
			if color != first_color:
				mixed_count += 1
				break
	return mixed_count

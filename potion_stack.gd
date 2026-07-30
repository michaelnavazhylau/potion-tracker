extends RefCounted

class_name PotionStack


var capacity: int:
	get:
		return _capacity

var size: int:
	get:
		return _colors.size()

var is_empty: bool:
	get:
		return _colors.is_empty()

var is_full: bool:
	get:
		return _colors.size() >= _capacity


var _capacity: int
var _colors: Array[PotionColors.PotionColor] = []


func _init(stack_capacity: int) -> void:
	assert(
		stack_capacity > 0,
		"PotionStack capacity must be greater than zero."
	)

	_capacity = stack_capacity


func load_colors(
	initial_colors: Array[PotionColors.PotionColor]
) -> void:
	assert(
		initial_colors.size() <= _capacity,
		"Initial colors exceed PotionStack capacity."
	)

	_colors.clear()

	for potion_color in initial_colors:
		assert(
			potion_color != PotionColors.PotionColor.EMPTY,
			"PotionStack cannot contain EMPTY entries."
		)

		_colors.append(potion_color)


func get_colors() -> Array[PotionColors.PotionColor]:
	# Return a copy so outside code cannot bypass the stack invariants.
	return _colors.duplicate()


func get_color_at(index: int) -> PotionColors.PotionColor:
	assert(
		index >= 0 and index < _colors.size(),
		"PotionStack index is out of bounds."
	)

	return _colors[index]


func empty_volume() -> int:
	return _capacity - _colors.size()


func top_color() -> PotionColors.PotionColor:
	if _colors.is_empty():
		return PotionColors.PotionColor.EMPTY

	return _colors.back()


func top_run_size() -> int:
	if _colors.is_empty():
		return 0

	var candidate_color := top_color()
	var run_size := 0

	for index in range(_colors.size() - 1, -1, -1):
		if _colors[index] != candidate_color:
			break

		run_size += 1

	return run_size


func can_accept(
	candidate_color: PotionColors.PotionColor
) -> bool:
	if candidate_color == PotionColors.PotionColor.EMPTY:
		return false

	if is_full:
		return false

	return is_empty or top_color() == candidate_color


func push_color(
	potion_color: PotionColors.PotionColor
) -> bool:
	if potion_color == PotionColors.PotionColor.EMPTY:
		return false

	if is_full:
		return false

	if not can_accept(potion_color):
		return false

	_colors.push_back(potion_color)

	return true


func pop_color() -> PotionColors.PotionColor:
	if _colors.is_empty():
		return PotionColors.PotionColor.EMPTY

	return _colors.pop_back()


func get_transfer_amount(target_stack: PotionStack) -> int:
	if target_stack == self:
		return 0

	if is_empty:
		return 0

	var candidate_color := top_color()

	if not target_stack.can_accept(candidate_color):
		return 0

	return min(
		top_run_size(),
		target_stack.empty_volume()
	)


func transfer_to(target_stack: PotionStack) -> int:
	var transfer_amount := get_transfer_amount(target_stack)

	if transfer_amount <= 0:
		return 0

	for index in range(transfer_amount):
		var moved_color := pop_color()

		# get_transfer_amount() has already established that every
		# move is legal and that the target has enough capacity.
		var pushed_successfully := target_stack.push_color(moved_color)

		assert(
			pushed_successfully,
			"PotionStack transfer violated an established invariant."
		)

	return transfer_amount

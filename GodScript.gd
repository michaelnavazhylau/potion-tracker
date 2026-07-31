extends Node2D


const BOTTLE_SIZE := Vector2(180.0, 270.0)
const POTION_SCENE := preload("res://FluidPotion.tscn")
const PUZZLE_GENERATOR := preload("res://PuzzleGenerator.gd")
const SIDE_MARGIN := 36.0
const STATUS_TOP_MARGIN := 24.0
const STATUS_HEIGHT := 126.0
const STATUS_BOARD_GAP := 24.0
const BOTTOM_MARGIN := 36.0
const POTION_GAP := 24.0
const MIN_POTION_SCALE := 0.50
const MAX_POTION_SCALE := 1.0


@onready var potions: Array[FluidPotion] = []
@onready var status_margin: MarginContainer = $UI/StatusMargin
@onready var status_label: Label = (
	$UI/StatusMargin/StatusPanel/StatusContent/StatusLabel
)
@onready var reset_button: Button = (
	$UI/StatusMargin/StatusPanel/StatusContent/Controls/ResetButton
)
@onready var difficulty_buttons: Array[Button] = [
	$UI/StatusMargin/StatusPanel/StatusContent/Controls/EasyButton,
	$UI/StatusMargin/StatusPanel/StatusContent/Controls/MediumButton,
	$UI/StatusMargin/StatusPanel/StatusContent/Controls/HardButton,
]
@onready var new_puzzle_button: Button = (
	$UI/StatusMargin/StatusPanel/StatusContent/Controls/NewPuzzleButton
)


var _selected_potion: FluidPotion
var _pour_in_progress := false
var _current_puzzle: Array = []
var _selected_difficulty := PUZZLE_GENERATOR.Difficulty.EASY


func _ready() -> void:
	for child in get_children():
		if child is FluidPotion:
			potions.append(child)

	for potion in potions:
		potion.potion_pressed.connect(_on_potion_pressed)

	var difficulty_group := ButtonGroup.new()
	for index in range(difficulty_buttons.size()):
		var difficulty_button := difficulty_buttons[index]
		difficulty_button.button_group = difficulty_group
		difficulty_button.pressed.connect(
			_on_difficulty_pressed.bind(index)
		)
	difficulty_buttons[_selected_difficulty].button_pressed = true

	reset_button.pressed.connect(_on_reset_pressed)
	new_puzzle_button.pressed.connect(_on_new_puzzle_pressed)
	get_viewport().size_changed.connect(_apply_responsive_layout)

	_current_puzzle = _capture_current_puzzle()
	_apply_responsive_layout()
	_set_status("Select a filled potion, then select its destination.")


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe_insets := _get_safe_insets(viewport_size)
	_layout_status(viewport_size, safe_insets)
	_layout_potions(viewport_size, safe_insets)


func _layout_status(viewport_size: Vector2, safe_insets: Vector4) -> void:
	status_margin.offset_left = safe_insets.x + SIDE_MARGIN
	status_margin.offset_top = safe_insets.y + STATUS_TOP_MARGIN
	status_margin.offset_right = -(safe_insets.z + SIDE_MARGIN)
	status_margin.offset_bottom = (
		status_margin.offset_top + STATUS_HEIGHT
	)


func _layout_potions(viewport_size: Vector2, safe_insets: Vector4) -> void:
	var is_portrait := viewport_size.x < viewport_size.y
	var columns := _get_column_count(is_portrait)
	var rows := ceili(float(potions.size()) / float(columns))
	var board_position := Vector2(
		safe_insets.x + SIDE_MARGIN,
		safe_insets.y + STATUS_TOP_MARGIN + STATUS_HEIGHT
			+ STATUS_BOARD_GAP
	)
	var board_size := Vector2(
		viewport_size.x - board_position.x - safe_insets.z - SIDE_MARGIN,
		viewport_size.y - board_position.y - safe_insets.w - BOTTOM_MARGIN
	)
	board_size = board_size.max(Vector2.ONE)

	var available_cell_size := Vector2(
		(board_size.x - POTION_GAP * float(columns - 1))
			/ float(columns),
		(board_size.y - POTION_GAP * float(rows - 1)) / float(rows)
	)
	var fit_scale := minf(
		available_cell_size.x / BOTTLE_SIZE.x,
		available_cell_size.y / BOTTLE_SIZE.y
	)
	var potion_scale := clampf(
		fit_scale,
		MIN_POTION_SCALE,
		MAX_POTION_SCALE
	)
	var scaled_bottle_size := BOTTLE_SIZE * potion_scale
	var grid_size := Vector2(
		scaled_bottle_size.x * float(columns)
			+ POTION_GAP * float(columns - 1),
		scaled_bottle_size.y * float(rows)
			+ POTION_GAP * float(rows - 1)
	)
	var grid_position := board_position + (board_size - grid_size) * 0.5

	for index in potions.size():
		var column := index % columns
		var row := index / columns
		var potion := potions[index]
		potion.scale = Vector2.ONE * potion_scale
		potion.position = grid_position + Vector2(
			float(column) * (scaled_bottle_size.x + POTION_GAP),
			float(row) * (scaled_bottle_size.y + POTION_GAP)
		)


func _get_column_count(is_portrait: bool) -> int:
	if is_portrait:
		if potions.size() <= 4:
			return 2
		return 3

	if potions.size() <= 4:
		return potions.size()
	return mini(5, potions.size())


func _get_safe_insets(viewport_size: Vector2) -> Vector4:
	var window_size := Vector2(DisplayServer.window_get_size())
	var window_position := Vector2(DisplayServer.window_get_position())
	var safe_area := Rect2(DisplayServer.get_display_safe_area())

	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	if safe_area.size.x <= 0.0 or safe_area.size.y <= 0.0:
		return Vector4.ZERO

	var window_rect := Rect2(window_position, window_size)
	var visible_safe_area := safe_area.intersection(window_rect)
	if visible_safe_area.size.x <= 0.0 or visible_safe_area.size.y <= 0.0:
		return Vector4.ZERO

	var local_safe_position := visible_safe_area.position - window_position
	var local_safe_end := visible_safe_area.end - window_position
	var logical_scale := viewport_size / window_size
	return Vector4(
		local_safe_position.x * logical_scale.x,
		local_safe_position.y * logical_scale.y,
		(window_size.x - local_safe_end.x) * logical_scale.x,
		(window_size.y - local_safe_end.y) * logical_scale.y
	)


func _on_potion_pressed(potion: FluidPotion) -> void:
	if _pour_in_progress:
		return
	if potion.is_complete():
		_set_status("That potion is complete and corked.")
		return

	if _selected_potion == null:
		if potion.potion_stack.is_empty:
			_set_status("That potion is empty. Select a filled potion first.")
			return

		_select_potion(potion)
		return

	if potion == _selected_potion:
		_clear_selection()
		_set_status("Selection cancelled.")
		return

	if not _selected_potion.can_pour_into(potion):
		if potion.potion_stack.is_empty:
			_set_status("That pour is not allowed by the stack rules.")
			return

		_select_potion(potion)
		return

	var source_potion := _selected_potion
	_clear_selection()
	_pour_in_progress = true

	var poured_successfully := source_potion.pour(potion)
	assert(poured_successfully, (
		"A pour validated by can_pour_into() unexpectedly failed."
	))
	_set_status("Pouring...")

	var transition_duration := maxf(
		source_potion.fill_duration,
		potion.fill_duration
	)

	if potion.is_complete():
		transition_duration += potion.cork_duration

	await get_tree().create_timer(transition_duration).timeout

	_pour_in_progress = false

	if _is_puzzle_solved():
		_set_status("Solved! Each filled potion contains one color.")
	else:
		_set_status("Select the next potion to pour.")


func _on_reset_pressed() -> void:
	if _pour_in_progress:
		_set_status("Wait for the current pour to finish before resetting.")
		return

	_load_puzzle(_current_puzzle)
	_set_status("Puzzle reset. Select a filled potion.")


func _on_new_puzzle_pressed() -> void:
	if _pour_in_progress:
		_set_status(
			"Wait for the current pour to finish before starting a new puzzle."
		)
		return

	var generated: Dictionary = PUZZLE_GENERATOR.generate(
		_selected_difficulty
	)
	_current_puzzle = _duplicate_puzzle(generated["bottles"])
	_load_puzzle(_current_puzzle)
	_set_status(
		"%s puzzle generated. Select a filled potion."
		% PUZZLE_GENERATOR.get_difficulty_name(_selected_difficulty)
	)


func _on_difficulty_pressed(difficulty: int) -> void:
	_selected_difficulty = difficulty


func _load_puzzle(bottles: Array) -> void:
	_clear_selection()
	_ensure_potion_count(bottles.size())

	for index in range(bottles.size()):
		var typed_colors: Array[PotionColors.PotionColor] = []
		for color: int in bottles[index]:
			typed_colors.append(color as PotionColors.PotionColor)
		potions[index].load_colors(typed_colors)

	_apply_responsive_layout()


func _ensure_potion_count(required_count: int) -> void:
	while potions.size() > required_count:
		var removed_potion: FluidPotion = potions.pop_back()
		remove_child(removed_potion)
		removed_potion.queue_free()

	while potions.size() < required_count:
		var potion: FluidPotion = POTION_SCENE.instantiate()
		potion.name = "Potion%d" % (potions.size() + 1)
		add_child(potion)
		potion.potion_pressed.connect(_on_potion_pressed)
		potions.append(potion)


func _capture_current_puzzle() -> Array:
	var bottles: Array = []
	for potion in potions:
		bottles.append(potion.potion_stack.get_colors())
	return _duplicate_puzzle(bottles)


func _duplicate_puzzle(bottles: Array) -> Array:
	var duplicate: Array = []
	for bottle: Array in bottles:
		duplicate.append(bottle.duplicate())
	return duplicate


func _select_potion(potion: FluidPotion) -> void:
	if _selected_potion != null:
		_selected_potion.deselect_potion()

	_selected_potion = potion
	_selected_potion.select_potion()
	_set_status("Now select a destination potion.")


func _clear_selection() -> void:
	if _selected_potion != null:
		_selected_potion.deselect_potion()

	_selected_potion = null


func _is_puzzle_solved() -> bool:
	for potion in potions:
		if not potion.is_solved():
			return false

	return true


func _set_status(message: String) -> void:
	status_label.text = message

extends Node2D


@onready var potions: Array[FluidPotion] = [
	$Potion1,
	$Potion2,
	$Potion3,
	$Potion4,
]
@onready var status_label: Label = $UI/StatusLabel


var _selected_potion: FluidPotion
var _pour_in_progress := false


func _ready() -> void:
	for potion in potions:
		potion.potion_pressed.connect(_on_potion_pressed)

	_set_status("Select a filled potion, then select its destination.")


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

extends Node2D

class_name PotionBottle


var potion_selected: bool = false

var potion_stack: PotionStack

# These nodes are visual slots only.
# Child order must be bottom-to-top.
var liquid_slots: Array[PotionLiquid] = []


func _ready() -> void:
	_initialize_liquid_slots()
	_initialize_potion_stack()
	_sync_liquid_slots()


func _initialize_liquid_slots() -> void:
	liquid_slots.clear()

	for child in get_children():
		if child is PotionLiquid:
			liquid_slots.append(child)

	assert(
		not liquid_slots.is_empty(),
		"PotionBottle requires at least one PotionLiquid child."
	)


func _initialize_potion_stack() -> void:
	var initial_colors: Array[PotionColors.PotionColor] = []
	var found_empty_slot := false

	for liquid_slot in liquid_slots:
		var slot_color := liquid_slot.potion_color

		if slot_color == PotionColors.PotionColor.EMPTY:
			found_empty_slot = true
			continue

		assert(
			not found_empty_slot,
			(
				"PotionBottle has a filled slot above an empty slot. "
				+ "PotionLiquid children must be ordered bottom-to-top, "
				+ "with all empty slots above all filled slots."
			)
		)

		initial_colors.append(slot_color)

	potion_stack = PotionStack.new(liquid_slots.size())
	potion_stack.load_colors(initial_colors)


func _sync_liquid_slots() -> void:
	assert(
		potion_stack.capacity == liquid_slots.size(),
		"PotionStack capacity must match the number of visual slots."
	)

	for index in range(liquid_slots.size()):
		if index < potion_stack.size:
			liquid_slots[index].potion_color = (
				potion_stack.get_color_at(index)
			)
		else:
			liquid_slots[index].potion_color = (
				PotionColors.PotionColor.EMPTY
			)


func pour(target_bottle: PotionBottle) -> bool:
	if target_bottle == null:
		return false

	if target_bottle == self:
		return false

	var amount_transferred := potion_stack.transfer_to(
		target_bottle.potion_stack
	)

	if amount_transferred <= 0:
		return false

	_sync_liquid_slots()
	target_bottle._sync_liquid_slots()

	return true


func can_pour_into(target_bottle: PotionBottle) -> bool:
	if target_bottle == null:
		return false

	if target_bottle == self:
		return false

	return (
		potion_stack.get_transfer_amount(
			target_bottle.potion_stack
		)
		> 0
	)


func select_bottle() -> void:
	if potion_selected:
		return

	potion_selected = true

	# TODO: Highlight the selected potion bottle.


func deselect_bottle() -> void:
	if not potion_selected:
		return

	potion_selected = false

	# TODO: Remove the selected potion bottle highlight.

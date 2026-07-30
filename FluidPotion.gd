extends Node2D

class_name FluidPotion


signal potion_pressed(potion: FluidPotion)


const CAPACITY := 4
const CORK_REST_POSITION := Vector2(90.0, 30.0)
const CORK_DROP_DISTANCE := 24.0
const LIQUID_COLOR_PARAMETERS := [
	"layer_color_0",
	"layer_color_1",
	"layer_color_2",
	"layer_color_3",
]


@export var initial_colors: Array[PotionColors.PotionColor] = []
@export_range(0.0, 2.0, 0.05) var fill_duration := 0.45
@export_range(0.0, 1.0, 0.05) var cork_duration := 0.3

@onready var liquid: Sprite2D = $Liquid
@onready var bottle_overlay: Sprite2D = $BottleOverlay
@onready var selection_outline: Sprite2D = $SelectionOutline
@onready var cork: Sprite2D = $Cork
@onready var hit_area: Area2D = $HitArea


var potion_selected := false
var corked := false
var potion_stack: PotionStack

var fill_amount: float:
	get:
		return _fill_amount
	set(value):
		_fill_amount = clampf(value, 0.0, 1.0)
		_set_shader_parameter("fill_amount", _fill_amount)


var _fill_amount := 0.0
var _displayed_colors: Array[PotionColors.PotionColor] = []
var _fill_tween: Tween
var _cork_tween: Tween


func _ready() -> void:
	_make_material_unique()
	_initialize_potion_stack()
	_sync_visuals(false)
	hit_area.input_event.connect(_on_hit_area_input_event)


func _make_material_unique() -> void:
	assert(liquid.material is ShaderMaterial, (
		"FluidPotion Liquid requires a ShaderMaterial."
	))
	liquid.material = liquid.material.duplicate()


func _initialize_potion_stack() -> void:
	assert(initial_colors.size() <= CAPACITY, (
		"FluidPotion initial colors exceed its capacity."
	))

	potion_stack = PotionStack.new(CAPACITY)
	potion_stack.load_colors(initial_colors)


func pour(target_potion: FluidPotion) -> bool:
	if target_potion == null or target_potion == self:
		return false

	var amount_transferred := potion_stack.transfer_to(
		target_potion.potion_stack
	)

	if amount_transferred <= 0:
		return false

	_sync_visuals(true)
	target_potion._sync_visuals(true)
	return true


func can_pour_into(target_potion: FluidPotion) -> bool:
	if target_potion == null or target_potion == self:
		return false

	return potion_stack.get_transfer_amount(
		target_potion.potion_stack
	) > 0


func select_potion() -> void:
	potion_selected = true
	selection_outline.visible = true


func deselect_potion() -> void:
	potion_selected = false
	selection_outline.visible = false


func is_solved() -> bool:
	return potion_stack.is_empty or is_complete()


func is_complete() -> bool:
	if not potion_stack.is_full:
		return false

	var colors := potion_stack.get_colors()
	var expected_color: PotionColors.PotionColor = colors.front()

	for potion_color in colors:
		if potion_color != expected_color:
			return false

	return true


func _on_hit_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	var was_pressed := false

	if event is InputEventMouseButton:
		was_pressed = (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
			and event.device != InputEvent.DEVICE_ID_EMULATION
		)
	elif event is InputEventScreenTouch:
		was_pressed = event.pressed

	if not was_pressed:
		return

	potion_pressed.emit(self)
	get_viewport().set_input_as_handled()


func set_fill_immediately(new_fill_amount: float) -> void:
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()

	fill_amount = new_fill_amount


func _sync_visuals(animated: bool) -> void:
	var target_colors := potion_stack.get_colors()
	var target_fill := float(potion_stack.size) / float(CAPACITY)

	if not animated or fill_duration <= 0.0:
		_displayed_colors = target_colors
		_apply_displayed_colors()
		set_fill_immediately(target_fill)
		_set_corked(is_complete(), false)
		return

	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()

	var is_growing := target_fill >= fill_amount
	var should_cork := is_complete()

	if not should_cork:
		_set_corked(false, true)

	if is_growing:
		_displayed_colors = target_colors
		_apply_displayed_colors()

	_fill_tween = create_tween()
	_fill_tween.set_trans(Tween.TRANS_SINE)
	_fill_tween.set_ease(Tween.EASE_IN_OUT)
	_fill_tween.tween_property(
		self,
		"fill_amount",
		target_fill,
		fill_duration
	)

	_fill_tween.finished.connect(func() -> void:
		if not is_growing:
			_displayed_colors = target_colors
			_apply_displayed_colors()

		if should_cork:
			_set_corked(true, true)
	)


func _set_corked(should_be_corked: bool, animated: bool) -> void:
	if _cork_tween != null and _cork_tween.is_valid():
		_cork_tween.kill()

	corked = should_be_corked

	if not animated or cork_duration <= 0.0:
		cork.visible = should_be_corked
		cork.position = CORK_REST_POSITION
		cork.scale = Vector2.ONE
		cork.modulate = Color.WHITE
		return

	if should_be_corked:
		cork.visible = true
		cork.position = CORK_REST_POSITION - Vector2(
			0.0,
			CORK_DROP_DISTANCE
		)
		cork.scale = Vector2(0.88, 0.88)
		cork.modulate = Color(1.0, 1.0, 1.0, 0.0)

		_cork_tween = create_tween().set_parallel(true)
		_cork_tween.tween_property(
			cork,
			"position",
			CORK_REST_POSITION,
			cork_duration
		).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_cork_tween.tween_property(
			cork,
			"scale",
			Vector2.ONE,
			cork_duration
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_cork_tween.tween_property(
			cork,
			"modulate:a",
			1.0,
			cork_duration * 0.5
		)
		return

	if not cork.visible:
		return

	_cork_tween = create_tween().set_parallel(true)
	_cork_tween.tween_property(
		cork,
		"position",
		CORK_REST_POSITION - Vector2(0.0, CORK_DROP_DISTANCE),
		cork_duration * 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_cork_tween.tween_property(
		cork,
		"modulate:a",
		0.0,
		cork_duration * 0.45
	)
	_cork_tween.chain().tween_callback(func() -> void:
		cork.visible = false
		cork.position = CORK_REST_POSITION
		cork.scale = Vector2.ONE
		cork.modulate = Color.WHITE
	)


func _apply_displayed_colors() -> void:
	for index in range(CAPACITY):
		var color := Color.TRANSPARENT

		if index < _displayed_colors.size():
			color = PotionColors.get_color(_displayed_colors[index])

		_set_shader_parameter(
			LIQUID_COLOR_PARAMETERS[index],
			color
		)


func _set_shader_parameter(parameter_name: String, value: Variant) -> void:
	var shader_material := liquid.material as ShaderMaterial
	assert(shader_material != null, (
		"FluidPotion Liquid shader material is unavailable."
	))
	shader_material.set_shader_parameter(parameter_name, value)

@tool
extends Polygon2D

class_name PotionLiquid


@export var potion_color: PotionColors.PotionColor = (
	PotionColors.PotionColor.EMPTY
):
	set(value):
		potion_color = value
		_update_rendering()


func _ready() -> void:
	_update_rendering()


func _update_rendering() -> void:
	color = PotionColors.get_color(potion_color)
	visible = potion_color != PotionColors.PotionColor.EMPTY

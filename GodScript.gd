extends Node2D

@onready var p1: PotionBottle = get_node("Potion1")
@onready var p2: PotionBottle = get_node("Potion2")

func _ready() -> void:
	assert(p1 != null, "Potion1 was not found")
	assert(p2 != null, "Potion2 was not found")
	
	p1.pour(p2)
	
	'''
	if p1.pour(p2) == false:
		print("bottle 1 could not pour into bottle 2")
	'''

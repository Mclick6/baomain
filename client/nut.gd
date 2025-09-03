extends Node2D

var food_type = "nut"

func _ready():
	add_to_group("items")
	set_meta("item_type", food_type)
	set_meta("is_food", true)

# Global.gd
extends Node

var rings = 0
var inventory = {}
var selected_item = ""
var selected_chao = ""
var player_data = {}
var chao_data = {}

func _ready():
	print("--- Global Autoloaded Successfully ---")
	# The following lines are temporarily commented out for the test.
	#if get_tree().root.has_node("ChaoManager"):
	#	ChaoManager.chao_data_updated.connect(_on_chao_data_updated)
	#	ChaoManager.chao_renamed.connect(_on_chao_renamed)
	#	ChaoManager.chao_removed.connect(_on_chao_removed)

# ... (the rest of your script can stay the same) ...

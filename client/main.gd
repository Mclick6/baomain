# main.gd
extends Node

@onready var game_world_container = $GameWorldContainer
@onready var login_screen = $UI/LoginScreen

var garden_scene = preload("res://garden.tscn")

func _ready():
	print("--- Main Scene Loaded Successfully ---")
	Server.login_success.connect(_on_login_success)

func _on_login_success(player_data):
	# Store the basic player data globally
	Global.player_data = player_data
	Global.rings = player_data.get("rings", 0)
	Global.inventory = player_data.get("inventory", {})

	# Load the chao data into the ChaoManager
	if player_data.has("chao_data") and player_data["chao_data"] is Array:
		ChaoManager.chao_list = player_data["chao_data"]

	# Now that all data is loaded, free the login screen
	login_screen.queue_free()
	
	# Create an instance of the garden scene and add it to the game world
	var garden = garden_scene.instantiate()
	game_world_container.add_child(garden)

# main.gd
extends Node

@onready var game_world_container = $GameWorldContainer
@onready var login_screen = $UI/LoginScreen

var garden_scene = preload("res://garden.tscn")

func _ready():
	print("--- Main Scene Loaded Successfully ---") # Add this line
	# Listen for the login_success signal
	Server.login_success.connect(_on_login_success)
	
	# REMOVED: Do NOT connect here anymore.
	# Server.connect_to_server()

func _on_login_success(player_data):
	# When login is successful, store the player's data globally
	Global.player_data = player_data
	
	# Remove the login screen
	login_screen.queue_free()
	
	# Create an instance of the garden scene and add it to the game world
	var garden = garden_scene.instantiate()
	game_world_container.add_child(garden)

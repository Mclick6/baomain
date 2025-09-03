# test.gd
extends Node

func _ready():
	print("--- Running minimal connection test ---")
	Server.connect_to_server()

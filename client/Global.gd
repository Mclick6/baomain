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

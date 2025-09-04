# PauseManager.gd
extends Node

var pause_menu_scene = preload("res://PauseMenu.tscn")
var pause_menu_instance = null

func _unhandled_input(event):
	# The Escape key now just calls our toggle function
	if event.is_action_pressed("ui_pause"):
		toggle_pause_menu()

func toggle_pause_menu():
	# This function now contains all the logic and can be called from anywhere.
	if get_tree().paused:
		_on_resume_pressed()
	else:
		get_tree().paused = true
		
		pause_menu_instance = pause_menu_scene.instantiate()
		
		pause_menu_instance.get_node("CenterContainer/VBoxContainer/ResumeButton").pressed.connect(_on_resume_pressed)
		pause_menu_instance.get_node("CenterContainer/VBoxContainer/OptionsButton").pressed.connect(_on_options_pressed)
		pause_menu_instance.get_node("CenterContainer/VBoxContainer/QuitButton").pressed.connect(_on_quit_to_desktop_pressed)
		
		get_tree().root.add_child(pause_menu_instance)

func _on_resume_pressed():
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
		pause_menu_instance = null
		get_tree().paused = false

func _on_options_pressed():
	print("Options button pressed!")

func _on_quit_to_desktop_pressed():
	get_tree().paused = false
	get_tree().quit()

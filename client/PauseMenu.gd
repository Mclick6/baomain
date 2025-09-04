# PauseMenu.gd
extends Control

func _input(event):
	# When the pause menu is open, this script will catch the 'ui_pause' action.
	if event.is_action_pressed("ui_pause"):
		# Tell the global manager to resume the game.
		PauseManager.toggle_pause_menu()
		# Mark the input as handled so nothing else processes this key press.
		get_viewport().set_input_as_handled()

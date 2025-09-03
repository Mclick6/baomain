# ChaoManager.gd
extends Node

var chao_list: Array = []
var chao_counter: int = 0
var autosave_timer: Timer

func _ready():
	# The client should NOT load a file on startup. It waits for the server.
	
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 30.0
	autosave_timer.autostart = true
	# We also disconnect local saving, as the server will handle it.
	# autosave_timer.timeout.connect(save_to_file) 
	add_child(autosave_timer)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# The client should just quit without trying to save locally.
		get_tree().quit()

# --- (Paste the rest of your original ChaoManager functions below) ---
# For example: create_and_add_new_chao, rename_chao, get_chao_data, etc.
# Just make sure the _ready function is the one from above.

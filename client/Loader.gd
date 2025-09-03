# Loader.gd
extends Node

var target_scene_path: String = ""
var loading_status = ResourceLoader.THREAD_LOAD_IN_PROGRESS

func _ready():
	# This ensures the loader is not tied to any specific scene
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	if target_scene_path == "":
		return

	# Check the status of the threaded load
	var status = ResourceLoader.load_threaded_get_status(target_scene_path)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		# Loading is complete! Get the packed scene resource
		var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
		# Reset for next time
		target_scene_path = ""
		# Change to the new scene
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("ERROR: Failed to load scene: %s" % target_scene_path)
		target_scene_path = ""
		# Go back to a main menu or safe scene
		get_tree().change_scene_to_file("res://garden.tscn")

# This is the function you'll call from your buttons
func load_scene(path: String):
	# First, switch to the loading screen. This is instantaneous.
	get_tree().change_scene_to_file("res://loading_screen.tscn")
	
	# Start loading the target scene in a background thread
	ResourceLoader.load_threaded_request(path)
	target_scene_path = path

extends Node2D

# This speed will now control the camera movement
var scroll_speed: float = 5.0
var chao_container: Node2D

@onready var camera: Camera2D = $Camera2D

func _ready():
	name = "Minigames"
	add_to_group("hub")
	
	chao_container = get_node_or_null("ChaoContainer")
	if not chao_container:
		chao_container = Node2D.new()
		chao_container.name = "ChaoContainer"
		chao_container.z_index = 0
		add_child(chao_container)
	
	call_deferred("_initialize_components")

func _initialize_components():
	ChaoManager.spawn_chao_in_hub(self)

func _process(delta):
	# NEW METHOD: Move the camera directly.
	# The ParallaxBackground will follow the camera automatically.
	if camera:
		camera.position.x += scroll_speed * delta

func _on_memory_match_button_pressed():
	Loader.load_scene("res://memory_match.tscn")

func _on_peggle_game_button_pressed():
	Loader.load_scene("res://peggle_game.tscn")

func _on_back_button_pressed():
	Loader.load_scene("res://garden.tscn")

func _exit_tree():
	if has_node("/root/Global"):
		ChaoManager.capture_chao_from_hub(self)

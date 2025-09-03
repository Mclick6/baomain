extends Node2D

var hub_name: String = "Minigames"
var scroll_speed: float = 20.0
var chao_container: Node2D

func _ready():
	name = "Minigames"
	add_to_group("hub")
	
	chao_container = get_node_or_null("ChaoContainer")
	if not chao_container:
		chao_container = Node2D.new()
		chao_container.name = "ChaoContainer"
		add_child(chao_container)
	
	call_deferred("_initialize_components")

func _initialize_components():
	ChaoManager.spawn_chao_in_hub(self)

func _process(delta):
	var parallax = get_node_or_null("ParallaxBackground")
	if parallax:
		parallax.scroll_offset.x += scroll_speed * delta

func _on_memory_match_button_pressed():
	Loader.load_scene("res://memory_match.tscn")

func _on_peggle_game_button_pressed():
	Loader.load_scene("res://peggle_game.tscn")

func _on_back_button_pressed():
	Loader.load_scene("res://garden.tscn")

func _exit_tree():
	if has_node("/root/Global"):
		ChaoManager.capture_chao_from_hub(self)

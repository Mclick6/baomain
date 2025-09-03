extends Node2D

signal egg_hatched(chao_data: Dictionary, pos: Vector2)

@onready var sprite = $Sprite2D
@onready var hatch_timer = $HatchTimer
@onready var click_area = $ClickArea
@onready var animation_player = $AnimationPlayer
var is_hatching = false
var hatch_progress = 0.0
var base_hatch_time = 10.0
var click_boost = 1.0
var min_hatch_time = 1.0

func _ready():
	add_to_group("interactable")
	if not hatch_timer.is_connected("timeout", Callable(self, "_on_hatch_complete")):
		hatch_timer.timeout.connect(_on_hatch_complete)
	click_area.input_event.connect(_on_area_input_event)
	animation_player.play("shake")
	call_deferred("_start_hatching")

func _process(delta):
	if is_hatching and not hatch_timer.is_stopped():
		var current_time_left = hatch_timer.time_left
		hatch_progress = clamp(1.0 - (current_time_left / base_hatch_time), 0.0, 1.0)
		if animation_player and animation_player.has_animation("shake"):
			animation_player.speed_scale = 1.0 + hatch_progress * 2.0

func _on_area_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_egg_clicked()
		get_viewport().set_input_as_handled()

func _on_egg_clicked():
	if not is_hatching:
		_start_hatching()
		return
	if hatch_timer.time_left > min_hatch_time:
		var new_time = max(hatch_timer.time_left - click_boost, min_hatch_time)
		hatch_timer.stop()
		hatch_timer.start(new_time)
		if ChatManager: ChatManager.add_chat_message("Egg clicked! Hatching faster!")
		if new_time <= min_hatch_time:
			_force_hatch()

func _start_hatching():
	if is_hatching: return
	is_hatching = true
	hatch_timer.start(base_hatch_time)
	if ChatManager: ChatManager.add_chat_message("Egg started hatching!")

func _force_hatch():
	if is_hatching and not hatch_timer.is_stopped():
		hatch_timer.stop()
		_on_hatch_complete()

func _on_hatch_complete():
	if not is_hatching: return
	is_hatching = false
	# This line was causing the crash. It now correctly accesses chao_counter from ChaoManager.
	var chao_data = {
		"chao_name": "Chao" + str(ChaoManager.chao_counter + 1),
		"position": {"x": global_position.x, "y": global_position.y},
		"stats": {
			"swim": {"level": 0, "progress": 0.0},
			"fly": {"level": 0, "progress": 0.0},
			"run": {"level": 0, "progress": 0.0},
			"power": {"level": 0, "progress": 0.0},
			"stamina": {"level": 0, "progress": 0.0},
			"belly": 75.0,
			"mood": 75.0
		}
	}
	_create_hatch_explosion()
	egg_hatched.emit(chao_data, global_position)
	if ChatManager: ChatManager.add_chat_message("Egg hatched! A new Chao has been born!")
	
	var cleanup_timer = get_tree().create_timer(0.5)
	cleanup_timer.timeout.connect(queue_free)

func _create_hatch_explosion():
	for i in range(15):
		var particle = Sprite2D.new()
		var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		var texture = ImageTexture.create_from_image(image)
		particle.texture = texture
		particle.modulate = Color(randf(), randf_range(0.5, 1.0), 0, 1.0)
		var angle = randf() * TAU
		var speed = randf_range(50, 100)
		var direction = Vector2.RIGHT.rotated(angle)
		get_parent().add_child(particle)
		particle.global_position = global_position
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", global_position + direction * speed, 0.5)
		tween.chain().tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(particle.queue_free)

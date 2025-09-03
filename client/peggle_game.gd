extends Node2D

@onready var cannon = $Cannon
@onready var shoot_point = $Cannon/CannonSprite/ShootPoint
@onready var peg_container = $PegContainer
@onready var ball_container = $BallContainer
@onready var score_label = $UI/ScoreLabel
@onready var balls_label = $UI/BallsLabel
@onready var back_button = $UI/BackButton
@onready var aim_line = $AimLine

var balls_remaining: int = 10
var score: int = 0
var rings_earned: int = 0
var game_started: bool = false
var is_aiming: bool = true
var active_ball: RigidBody2D = null

var ball_scene = preload("res://peggle_ball.tscn")
var peg_scene = preload("res://peggle_peg.tscn")

var ball_speed: float = 800.0

func _ready():
	_setup_game()
	if back_button and not back_button.is_connected("pressed", Callable(self, "_on_back_pressed")):
		back_button.pressed.connect(Callable(self, "_on_back_pressed"))

func _setup_game():
	balls_remaining = 10
	score = 0
	rings_earned = 0
	game_started = true
	is_aiming = true

	# Safely remove all previous pegs and balls
	for child in peg_container.get_children():
		child.queue_free()
	for child in ball_container.get_children():
		child.queue_free()
	
	# Remove restart button if it exists
	var restart_button = $UI.get_node_or_null("RestartButton")
	if restart_button:
		restart_button.queue_free()

	cannon.position = Vector2(get_viewport_rect().size.x / 2, 80)

	_generate_pegs()
	_update_ui()

	aim_line.width = 3.0
	aim_line.default_color = Color(1, 1, 1, 0.5)
	aim_line.top_level = true
	_update_aim_line()

func _generate_pegs():
	randomize()
	var peg_positions = []
	var orange_peg_count = 25

	for i in range(100):
		var x_pos = randf_range(100, get_viewport_rect().size.x - 100)
		var y_pos = randf_range(200, get_viewport_rect().size.y - 200)
		peg_positions.append(Vector2(x_pos, y_pos))
	
	peg_positions.shuffle()

	for i in range(peg_positions.size()):
		var peg_pos = peg_positions[i]
		var peg_type = PegglePeg.PegType.ORANGE if i < orange_peg_count else PegglePeg.PegType.BLUE
		_create_peg(peg_pos, peg_type)
		
		# ADD THIS CHECK: This spreads the loading process over multiple frames.
		if i % 10 == 0:
			await get_tree().process_frame

func _create_peg(pos: Vector2, type: PegglePeg.PegType):
	if not peg_scene: return
	
	var peg = peg_scene.instantiate() as PegglePeg
	# Set the variable for the peg to use in its _ready() function
	peg.peg_type_to_set = type
	peg.position = pos
	peg_container.add_child(peg)
	peg.peg_hit.connect(_on_peg_hit)

func _input(event):
	if not game_started: return

	if is_aiming:
		if event is InputEventMouseMotion:
			_update_cannon_aim(event.position)
		elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_shoot_ball()

func _update_cannon_aim(mouse_pos: Vector2):
	cannon.look_at(mouse_pos)
	_update_aim_line()

func _update_aim_line():
	if not is_aiming:
		aim_line.clear_points()
		return

	var start_pos = shoot_point.global_position
	var direction = Vector2.RIGHT.rotated(cannon.global_rotation)
	var end_pos = start_pos + direction * 2000

	aim_line.points = [start_pos, end_pos]

func _shoot_ball():
	if balls_remaining <= 0 or active_ball != null: return

	is_aiming = false
	balls_remaining -= 1

	if not ball_scene: return
	
	active_ball = ball_scene.instantiate()
	active_ball.position = shoot_point.global_position
	ball_container.add_child(active_ball)

	var direction = Vector2.RIGHT.rotated(cannon.global_rotation)
	active_ball.apply_central_impulse(direction * ball_speed)

	if active_ball.has_signal("ball_stopped"):
		active_ball.ball_stopped.connect(_on_ball_stopped)
	
	aim_line.clear_points()
	_update_ui()

func _on_peg_hit(peg):
	score += peg.score_value
	rings_earned += peg.score_value / 10 # Example logic
	_update_ui()
	if _check_win_condition():
		_game_complete()

func _on_ball_collected(body):
	if body == active_ball:
		body.queue_free()
		active_ball = null
		_prepare_next_shot()

func _on_ball_stopped():
	if active_ball:
		active_ball.queue_free()
		active_ball = null
	_prepare_next_shot()

func _prepare_next_shot():
	if _check_win_condition():
		_game_complete()
		return
	if balls_remaining <= 0 and not _check_win_condition():
		_game_over()
		return

	await get_tree().create_timer(1.0).timeout
	is_aiming = true
	_update_aim_line()

func _check_win_condition() -> bool:
	for peg in peg_container.get_children():
		if peg is PegglePeg and peg.peg_type == PegglePeg.PegType.ORANGE and not peg.is_hit:
			return false
	return true

func _game_complete():
	game_started = false
	rings_earned += 100 
	_end_game()
	if has_node("/root/ChatManager"):
		ChatManager.add_chat_message("Congratulations! Score: %d, +100 ring bonus!" % score)


func _game_over():
	game_started = false
	_end_game()
	if has_node("/root/ChatManager"):
		ChatManager.add_chat_message("Game Over! Final Score: %d, Rings earned: %d" % [score, rings_earned])

func _end_game():
	# Re-enabled the saving logic
	if has_node("/root/Global"):
		Global.rings += rings_earned
	
	
	if not $UI.get_node_or_null("RestartButton"):
		var restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.text = "Play Again"
		restart_button.pressed.connect(_setup_game)
		$UI.add_child(restart_button)
		restart_button.position = Vector2(get_viewport_rect().size.x / 2 - 50, 150)

func _update_ui():
	if score_label:
		score_label.text = "Score: %d\nRings: %d" % [score, rings_earned]
	if balls_label:
		balls_label.text = "Balls: %d" % balls_remaining

func _on_back_pressed():
	# Re-enabled the saving logic for when the player leaves mid-game
	if game_started and rings_earned > 0:
		if has_node("/root/Global"):
			Global.rings += rings_earned
			
	
	get_tree().change_scene_to_file("res://minigames.tscn")

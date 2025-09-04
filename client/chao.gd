extends CharacterBody2D

var chao_name: String = ""
var stats: Dictionary = {
	"swim": {"level": 0, "progress": 0.0},
	"fly": {"level": 0, "progress": 0.0},
	"run": {"level": 0, "progress": 0.0},
	"power": {"level": 0, "progress": 0.0},
	"stamina": {"level": 0, "progress": 0.0},
	"belly": 75.0,
	"mood": 75.0
}
var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 100.0
var state: String = "idle"
var target_item: Node = null
var mood_timer: float = 5.0
var belly_timer: float = 5.0
var detected_balls: Array = []
var treadmill_timer: float = 0.0
const TREADMILL_DURATION: float = 15.0
const STAMINA_GAIN_PER_SECOND: float = 0.0533

func _ready():
	add_to_group("chao")
	
	var area = get_node_or_null("Area2D")
	if area:
		area.input_pickable = true
	var ball_area = get_node_or_null("BallDetectionArea")
	if ball_area:
		ball_area.monitoring = true
		ball_area.monitorable = false
	_update_animation()

func _physics_process(delta):
	mood_timer -= delta
	belly_timer -= delta
	if mood_timer <= 0:
		ChaoManager.update_chao_stat(chao_name, "mood", -0.5)
		mood_timer = 5.0
	if belly_timer <= 0:
		ChaoManager.update_chao_stat(chao_name, "belly", -0.5)
		belly_timer = 5.0

	if state == "on_treadmill":
		treadmill_timer -= delta
		if treadmill_timer > 0:
			ChaoManager.update_chao_stat(chao_name, "stamina", STAMINA_GAIN_PER_SECOND * delta * 100)
		else:
			state = "idle"
			target_item = null
			if ChatManager: ChatManager.add_chat_message("Chao %s finished treadmill training!" % chao_name)
		_update_garden_stats_display_safe()

	var chao_data = ChaoManager.get_chao_data(chao_name)
	if chao_data:
		var current_stats = chao_data.get("stats", stats)
		if current_stats["belly"] < 25.0:
			if state == "moving_to_item" and is_instance_valid(target_item):
				target_item.remove_meta("reserved_by")
			state = "idle"
			target_item = null
		else:
			if state == "idle" and current_stats["mood"] < 75.0:
				var ball = _find_nearest_ball()
				if ball:
					target_item = ball
					target_position = ball.position
					state = "chasing_ball"

			if state == "idle" and current_stats["belly"] < 75.0:
				var food = _find_nearest_food()
				if food:
					food.set_meta("reserved_by", self)
					target_item = food
					target_position = food.position
					state = "moving_to_item"

	match state:
		"idle":
			_handle_idle_state(delta)
		"wandering":
			_handle_wandering_state(delta)
		"moving_to_item":
			_handle_moving_to_item(delta)
		"chasing_ball":
			_handle_chasing_ball(delta)
		"moving_to_treadmill":
			_handle_moving_to_treadmill(delta)

	_update_animation()

func _handle_idle_state(_delta: float):
	if randf() < 0.01:
		target_position = position + Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		state = "wandering"
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _handle_wandering_state(_delta: float):
	var direction = (target_position - position).normalized()
	velocity = direction * move_speed
	if position.distance_to(target_position) < 10.0:
		state = "idle"
		velocity = Vector2.ZERO
	else:
		move_and_slide()

func _handle_moving_to_item(_delta: float):
	if not is_instance_valid(target_item):
		state = "idle"
		target_item = null
		return
	target_position = target_item.position
	var direction = (target_position - position).normalized()
	velocity = direction * move_speed
	if position.distance_to(target_position) < 10.0:
		_eat_food(target_item)
	else:
		move_and_slide()

func _handle_chasing_ball(_delta: float):
	if not is_instance_valid(target_item):
		state = "idle"
		target_item = null
		return
	target_position = target_item.position
	var direction = (target_position - position).normalized()
	velocity = direction * move_speed
	if position.distance_to(target_position) < 10.0:
		_kick_ball(target_item)
	else:
		move_and_slide()

func _handle_moving_to_treadmill(_delta: float):
	if not is_instance_valid(target_item):
		state = "idle"
		target_item = null
		return
	target_position = target_item.position
	var direction = (target_position - position).normalized()
	velocity = direction * move_speed
	if position.distance_to(target_position) < 10.0:
		state = "on_treadmill"
		velocity = Vector2.ZERO
		treadmill_timer = TREADMILL_DURATION
		if ChatManager: ChatManager.add_chat_message("Chao %s is on the treadmill!" % chao_name)
	else:
		move_and_slide()

# --- ADD THIS ENTIRE FUNCTION ---
func move_to_treadmill(treadmill: Node):
	if not is_instance_valid(treadmill):
		return
	
	# Forcefully interrupt the previous task
	if state == "moving_to_item" and is_instance_valid(target_item):
		target_item.remove_meta("reserved_by")
	
	# Give the new command
	target_item = treadmill
	target_position = treadmill.position
	state = "moving_to_treadmill"
# -----------------------------

func _find_nearest_food() -> Node:
	var foods = get_tree().get_nodes_in_group("items").filter(func(item): return item.get_meta("is_food", false) and not item.is_in_group("egg") and not item.has_meta("reserved_by"))
	if foods.is_empty():
		return null
	var nearest = foods[0]
	var min_distance = position.distance_to(nearest.position)
	for food in foods:
		var distance = position.distance_to(food.position)
		if distance < min_distance:
			min_distance = distance
			nearest = food
	return nearest

func _find_nearest_ball() -> Node:
	if detected_balls.is_empty():
		return null
	var nearest = detected_balls[0]
	var min_distance = position.distance_to(nearest.position)
	for ball in detected_balls:
		if is_instance_valid(ball):
			var distance = position.distance_to(ball.position)
			if distance < min_distance:
				min_distance = distance
				nearest = ball
	return nearest if is_instance_valid(nearest) else null

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not has_node("/root/Global"):
			return
		if Global.selected_item == "":
			Global.selected_chao = chao_name
			get_tree().call_group("chao", "set_highlight", false)
			set_highlight(true)
			if ChatManager: ChatManager.add_chat_message("Selected Chao %s" % chao_name)
			get_viewport().set_input_as_handled()

func _on_ball_detection_area_entered(area: Area2D):
	if area.is_in_group("items") and area.get_meta("item_type", "") == "ball" and is_instance_valid(area):
		if not detected_balls.has(area):
			detected_balls.append(area)

func _on_ball_detection_area_exited(area: Area2D):
	if area.is_in_group("items") and area.get_meta("item_type", "") == "ball":
		detected_balls.erase(area)
		if target_item == area:
			target_item = null
			state = "idle"

func set_highlight(is_selected: bool):
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		if is_selected:
			sprite.modulate = Color(1, 1, 0.5, 1)
			z_index = 2
		else:
			sprite.modulate = Color(1, 1, 1, 1)
			z_index = 1

func _eat_food(food: Node):
	if not is_instance_valid(food) or not food.get_meta("is_food", false):
		state = "idle"
		target_item = null
		return
	var food_type = food.get_meta("item_type", "nut")
	var stat_increase = 5.0 if food_type == "nut" else 10.0
	ChaoManager.update_chao_stat(chao_name, "belly", stat_increase)
	if ChatManager and ChatManager.has_method("add_chat_message"):
		ChatManager.add_chat_message("Chao %s ate a %s!" % [chao_name, food_type.capitalize()])
	food.queue_free()
	state = "idle"
	target_item = null
	_update_garden_stats_display_safe()

func _kick_ball(ball: Node):
	if not is_instance_valid(ball) or ball.get_meta("item_type", "") != "ball":
		state = "idle"
		target_item = null
		return
	var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	ball.call("throw", direction)
	ChaoManager.update_chao_stat(chao_name, "mood", 10.0)
	if ChatManager: ChatManager.add_chat_message("Chao %s kicked a ball!" % chao_name)
	_update_garden_stats_display_safe()
	target_item = null
	state = "idle"
	$AnimationPlayer.play("happy")

func _update_animation():
	var anim = "idle"
	var chao_data = ChaoManager.get_chao_data(chao_name)
	if chao_data:
		if velocity.length() > 5.0 or state == "on_treadmill":
			anim = "run"
		
		var current_stats = chao_data.get("stats", stats)
		if current_stats["belly"] < 25.0:
			anim = "sad"
		elif current_stats["mood"] > 75.0 and state != "on_treadmill":
			anim = "happy"
	if $AnimationPlayer.current_animation != anim:
		$AnimationPlayer.play(anim)

func serialize() -> Dictionary:
	return {
		"chao_name": chao_name,
		"position": {"x": position.x, "y": position.y},
		"stats": stats.duplicate(true)
	}

func deserialize(data: Dictionary):
	if data.has("chao_name"):
		chao_name = data["chao_name"]
	if data.has("position"):
		position = Vector2(data["position"].x, data["position"].y)
	
	if data.has("stats"):
		stats = data["stats"].duplicate(true)
		
	_update_animation()

func get_chao_name() -> String:
	return chao_name

func _update_garden_stats_display_safe():
	var root := get_tree().get_root()
	if root:
		var garden := root.get_node_or_null("Garden")
		if garden and garden.has_method("_update_chao_stats_display"):
			garden._update_chao_stats_display()

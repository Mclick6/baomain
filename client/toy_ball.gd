extends Area2D

var ball_velocity: Vector2 = Vector2.ZERO
var friction: float = 0.98
var bounce: float = 0.7

func _ready():
	add_to_group("items")
	set_meta("item_type", "ball")
	set_meta("is_food", false)
	collision_layer = 2
	collision_mask = 2
	monitorable = true
	monitoring = true
	if not is_connected("body_entered", _on_body_entered):
		body_entered.connect(_on_body_entered)
	if $AnimationPlayer:
		$AnimationPlayer.play("idle")
	else:
		ChatManager.add_chat_message("Error: AnimationPlayer not found on ToyBall")
	var timer = Timer.new()
	timer.wait_time = 60.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()
	print("ToyBall spawned at %s with 60-second timer" % position)

func _physics_process(delta):
	if ball_velocity.length() > 0:
		ball_velocity *= friction
		var new_position = position + ball_velocity * delta
		new_position.x = clamp(new_position.x, 0, 1280)
		new_position.y = clamp(new_position.y, 0, 720)
		if new_position.x <= 0 or new_position.x >= 1280:
			ball_velocity.x = -ball_velocity.x * bounce
			new_position.x = clamp(new_position.x, 0, 1280)
		if new_position.y <= 0 or new_position.y >= 720:
			ball_velocity.y = -ball_velocity.y * bounce
			new_position.y = clamp(new_position.y, 0, 720)
		position = new_position
		if $AnimationPlayer and $AnimationPlayer.current_animation != "hit":
			$AnimationPlayer.play("roll")
	else:
		if $AnimationPlayer and $AnimationPlayer.current_animation != "hit":
			$AnimationPlayer.play("idle")
	if ball_velocity.length() < 10.0:
		ball_velocity = Vector2.ZERO

func throw(direction: Vector2):
	if direction != Vector2.ZERO:
		ball_velocity = direction * 100
		if $AnimationPlayer:
			$AnimationPlayer.play("roll")
		else:
			ChatManager.add_chat_message("Error: AnimationPlayer not found on ToyBall")
		#print("ToyBall thrown with direction: %s, velocity: %s" % [direction, ball_velocity])

func _on_body_entered(body):
	if body.is_in_group("chao") and is_instance_valid(body):
		if $AnimationPlayer:
			$AnimationPlayer.play("hit")
		else:
			ChatManager.add_chat_message("Error: AnimationPlayer not found on ToyBall")
		#print("Chao %s hit ball at %s" % [body.get_chao_name(), position])

func _on_animation_finished(anim_name: String):
	if anim_name == "hit":
		if ball_velocity.length() > 0:
			if $AnimationPlayer:
				$AnimationPlayer.play("roll")
		else:
			if $AnimationPlayer:
				$AnimationPlayer.play("idle")

func _on_timer_timeout():
	queue_free()
	print("ToyBall at %s timed out after 60 seconds" % position)


func _on_timer_ready() -> void:
	pass # Replace with function body.

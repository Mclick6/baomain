extends RigidBody2D

signal ball_stopped

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var min_velocity_threshold: float = 10.0
var stop_timer: float = 0.0
var stop_check_duration: float = 1.0

func _ready():
	gravity_scale = 1.0
	linear_damp = 0.1
	angular_damp = 0.2
	contact_monitor = true
	max_contacts_reported = 4
	
	collision_layer = 2
	collision_mask = 1 | 4
	
	if sprite:
		sprite.texture = _create_ball_texture()
	
	if collision and not collision.shape:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 12
		collision.shape = circle_shape

	body_entered.connect(_on_body_entered)


func _create_ball_texture() -> ImageTexture:
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var center = Vector2(12, 12)
	
	for x in range(24):
		for y in range(24):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			
			if distance <= 12:
				var intensity = 1.0 - (distance / 12.0)
				var color = Color.WHITE.lerp(Color(0.8, 0.8, 1.0), intensity)
				color.a = 1.0
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _physics_process(delta):
	if linear_velocity.length() < min_velocity_threshold:
		stop_timer += delta
		if stop_timer >= stop_check_duration:
			ball_stopped.emit()
	else:
		stop_timer = 0.0

func _on_body_entered(body):
	if body.has_method("hit_by_ball"):
		body.hit_by_ball(self)

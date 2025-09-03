extends StaticBody2D
class_name PegglePeg

signal peg_hit(peg)

# --- NEW: Preload your peg images here ---
# Replace these paths with the actual paths to your .png files
const BLUE_PEG_TEXTURE = preload("res://imgs/blue_peg.png")
const ORANGE_PEG_TEXTURE = preload("res://imgs/orange_peg.png")
# -----------------------------------------

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

enum PegType { BLUE, ORANGE }

var peg_scores = {
	PegType.BLUE: 10,
	PegType.ORANGE: 100
}

var peg_type: PegType = PegType.BLUE
var score_value: int = 10
var is_hit: bool = false

# This variable will be set by the game script immediately after creation.
var peg_type_to_set: PegType = PegType.BLUE

func _ready():
	collision_layer = 4
	collision_mask = 2 # Only collides with balls
	# Call the setup function now. The engine guarantees the sprite is ready here.
	setup_peg(peg_type_to_set)

func setup_peg(type: PegType):
	peg_type = type
	score_value = peg_scores[type]
	if sprite:
		# Assign the correct preloaded texture based on the peg type
		if peg_type == PegType.BLUE:
			sprite.texture = BLUE_PEG_TEXTURE
		else: # ORANGE
			sprite.texture = ORANGE_PEG_TEXTURE

# The _create_peg_texture function is no longer needed and has been removed.

func hit_by_ball(_ball):
	if is_hit:
		return
	is_hit = true
	peg_hit.emit(self)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.1).set_delay(0.1)
	await tween.finished
	queue_free()

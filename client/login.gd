# login.gd
extends Control

@onready var username_field = $CenterContainer/VBoxContainer/UsernameField
@onready var password_field = $CenterContainer/VBoxContainer/PasswordField
@onready var login_button = $CenterContainer/VBoxContainer/HBoxContainer/LoginButton
@onready var register_button = $CenterContainer/VBoxContainer/HBoxContainer/RegisterButton
@onready var error_label = $CenterContainer/VBoxContainer/ErrorLabel
@onready var background_rect: TextureRect = $BackgroundRect
var background_textures: Array[Texture2D] = [
	preload("res://imgs/backgrounds/login/login-background-1.png"),
	preload("res://imgs/backgrounds/login/login-background-2.png"),
	preload("res://imgs/backgrounds/login/login-background-3.png"),
	preload("res://imgs/backgrounds/login/login-background-4.png")
]
var current_background_index: int = 0

func _ready():
	# --- Set the initial background image and fix the input issue ---
	if not background_textures.is_empty():
		background_rect.texture = background_textures[0]
	
	# **THIS IS THE FIX:** Make the background ignore mouse clicks.
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- Existing login logic ---
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	
	Server.connected_to_server.connect(_on_connected_to_server)
	Server.connection_failed.connect(_on_connection_failed)
	Server.login_success.connect(_on_login_success)
	Server.login_failure.connect(_on_login_failure)
	Server.registration_success.connect(_on_registration_success)
	Server.registration_failure.connect(_on_registration_failure)
	
	error_label.text = "Connecting to server..."
	login_button.disabled = true
	register_button.disabled = true

	Server.connect_to_server()

func _on_background_timer_timeout():
	if background_textures.size() < 2:
		return

	var tween = create_tween()
	tween.tween_property(background_rect, "modulate:a", 1.0, 1.0)
	tween.tween_callback(func():
		current_background_index = (current_background_index + 1) % background_textures.size()
		background_rect.texture = background_textures[current_background_index]
	)
	tween.tween_property(background_rect, "modulate:a", 1.0, 1.0)

# --- The rest of your login functions remain the same ---

func _on_connected_to_server():
	error_label.text = "Connected. Please log in or register."
	login_button.disabled = false
	register_button.disabled = false

func _on_connection_failed():
	error_label.text = "Connection failed. Could not reach the server."

func _on_login_pressed():
	var username = username_field.text
	var password = password_field.text
	if username.is_empty() or password.is_empty():
		error_label.text = "Username and password cannot be empty."
		return
	
	error_label.text = "Attempting to log in..."
	Server.request_login(username, password)

func _on_register_pressed():
	var username = username_field.text
	var password = password_field.text
	if username.is_empty() or password.is_empty():
		error_label.text = "Username and password cannot be empty."
		return
		
	error_label.text = "Attempting to register..."
	Server.request_registration(username, password)

func _on_login_success(_player_data):
	error_label.text = "Login successful!"
	
func _on_login_failure(reason):
	error_label.text = "Login failed: %s" % reason

func _on_registration_success():
	error_label.text = "Registration successful! You can now log in."

func _on_registration_failure(reason):
	error_label.text = "Registration failed: %s" % reason

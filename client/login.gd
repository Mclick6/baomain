# login.gd
extends Control

@onready var username_field = $CenterContainer/VBoxContainer/UsernameField
@onready var password_field = $CenterContainer/VBoxContainer/PasswordField
@onready var login_button = $CenterContainer/VBoxContainer/HBoxContainer/LoginButton
@onready var register_button = $CenterContainer/VBoxContainer/HBoxContainer/RegisterButton
@onready var error_label = $CenterContainer/VBoxContainer/ErrorLabel

func _ready():
	print("CLIENT: Login screen ready. Connecting signals.")
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

	print("CLIENT: Requesting connection to server...")
	Server.connect_to_server()

func _on_connected_to_server():
	print("CLIENT: SUCCESS! Custom 'connected_to_server' signal received. Enabling buttons.")
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

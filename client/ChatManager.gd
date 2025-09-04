# ChatManager.gd
extends Node

var chat_container: PanelContainer
var chat_text: RichTextLabel
var input_field: LineEdit
var toggle_button: Button
var menu_button: Button
var chat_layer: CanvasLayer

func _ready():
	Server.login_success.connect(_setup_and_show_chat)

func _setup_and_show_chat(_player_data):
	chat_layer = CanvasLayer.new()
	chat_layer.name = "ChatLayer"
	chat_layer.layer = 50
	add_child(chat_layer)
	
	chat_container = PanelContainer.new()
	chat_container.name = "MainChatContainer"
	chat_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat_container.size = Vector2(400, 200)
	chat_container.position = Vector2(10, -210)
	chat_layer.add_child(chat_container)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat_container.add_child(vbox)

	chat_text = RichTextLabel.new()
	chat_text.name = "ChatText"
	chat_text.bbcode_enabled = true
	chat_text.scroll_following = true
	chat_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(chat_text)
	
	input_field = LineEdit.new()
	input_field.name = "ChatInput"
	# --- ADD THESE LINES BACK ---
	input_field.placeholder_text = "Type here..."
	input_field.editable = true
	# --------------------------
	input_field.custom_minimum_size.y = 30
	input_field.text_submitted.connect(_on_chat_input_submitted)
	vbox.add_child(input_field)
	
	toggle_button = Button.new()
	toggle_button.name = "ToggleChatButton"
	toggle_button.text = "Hide Chat"
	toggle_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle_button.position = Vector2(-130, 10)
	toggle_button.size = Vector2(120, 30)
	toggle_button.pressed.connect(_on_toggle_chat_pressed)
	chat_layer.add_child(toggle_button)
	
	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "Menu"
	menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_button.position = Vector2(-260, 10)
	menu_button.size = Vector2(120, 30)
	menu_button.pressed.connect(_on_menu_button_pressed)
	chat_layer.add_child(menu_button)

	add_chat_message("Welcome to Egg Bloom Haven!")
	Server.chat_message_received.connect(add_chat_message)

func _on_menu_button_pressed():
	PauseManager.toggle_pause_menu()

func add_chat_message(message: String):
	if is_instance_valid(chat_text):
		chat_text.append_text(message + "\n")

func _on_chat_input_submitted(text: String):
	if text.strip_edges() != "":
		Server.send_chat_message(text)
		input_field.clear()
		input_field.grab_focus()

func _on_toggle_chat_pressed():
	if is_instance_valid(chat_container):
		chat_container.visible = not chat_container.visible
		toggle_button.text = "Show Chat" if not chat_container.visible else "Hide Chat"

# server/server.gd (Final Version)
extends Node

const Session = preload("res://Session.gd")

const DEFAULT_PORT = 7777
var peer = ENetMultiplayerPeer.new()
var sessions = {} # {peer_id: Session object}

@onready var db_manager = $DatabaseManager

func _ready():
	print("--- Initializing Dedicated Server ---")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var error = peer.create_server(DEFAULT_PORT)
	if error != OK:
		get_tree().quit()
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server listening on port %d." % DEFAULT_PORT)
# Add a timer for pings
	var ping_timer = Timer.new()
	ping_timer.wait_time = 5.0 # Ping every 5 seconds
	ping_timer.autostart = true
	add_child(ping_timer)
	ping_timer.timeout.connect(_on_ping_timer_timeout)

func _on_ping_timer_timeout():
	for peer_id in sessions:
		rpc_id(peer_id, "_ping")

# This is called when a client pongs back
@rpc("any_peer")
func _pong():
	var sender_id = multiplayer.get_remote_sender_id()
	# You could use this to calculate and store player latency (ping time)
	# print("Received pong from peer %d" % sender_id)
	pass
	
func _on_peer_connected(id):
	print("SERVER: A client has connected! Peer ID: %d" % id)
	var new_session = Session.new()
	new_session.name = str(id)
	sessions[id] = new_session
	add_child(new_session)

func _on_peer_disconnected(id):
	print("Peer disconnected: %d" % id)
	if sessions.has(id):
		var username = sessions[id].username if sessions[id].username != "" else "A player"
		sessions[id].queue_free()
		sessions.erase(id)
		_broadcast_chat_message("[Server] %s has disconnected." % username)

func _broadcast_chat_message(message: String):
	for peer_id in sessions:
		if sessions[peer_id].username != "":
			rpc_id(peer_id, "_rpc_receive_chat_message", message)

# --- SERVER-SIDE RPC API ---
@rpc("any_peer", "reliable")
func _request_registration(username, password):
	var sender_id = multiplayer.get_remote_sender_id()
	var result: Dictionary = db_manager.register_account(username, password)
	if result.get("success"):
		rpc_id(sender_id, "_rpc_registration_success")
	else:
		rpc_id(sender_id, "_rpc_registration_failure", result.get("reason", "Unknown error."))

@rpc("any_peer", "reliable")
func _request_login(username, password):
	var sender_id = multiplayer.get_remote_sender_id()
	var player_data: Dictionary = db_manager.login(username, password)
	if not player_data.is_empty():
		if sessions.has(sender_id):
			sessions[sender_id].username = username
			sessions[sender_id].account_id = player_data.get("account_id")
		rpc_id(sender_id, "_rpc_login_success", player_data)
		_broadcast_chat_message("[Server] %s has connected." % username)
	else:
		rpc_id(sender_id, "_rpc_login_failure", "Invalid credentials.")

@rpc("any_peer", "reliable")
func _request_chat_message(message_text):
	var sender_id = multiplayer.get_remote_sender_id()
	var username = "Guest"
	if sessions.has(sender_id) and sessions[sender_id].username != "":
		username = sessions[sender_id].username
	var formatted_message = "%s: %s" % [username, message_text]
	_broadcast_chat_message(formatted_message)

@rpc("any_peer", "reliable")
func _request_save_data(player_data: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	if sessions.has(sender_id) and sessions[sender_id].account_id > 0:
		var account_id = sessions[sender_id].account_id
		db_manager.save_player_data(account_id, player_data)
	else:
		print("ERROR: Received save request from a non-logged-in user.")

# --- CLIENT-SIDE RPC Stubs (for checksum matching) ---
@rpc("call_local", "reliable")
func _rpc_login_success(_player_data): pass
@rpc("call_local", "reliable")
func _rpc_login_failure(_reason): pass
@rpc("call_local", "reliable")
func _rpc_registration_success(): pass
@rpc("call_local", "reliable")
func _rpc_registration_failure(_reason): pass
@rpc("call_local", "reliable")
func _rpc_receive_chat_message(_message): pass
@rpc("call_local")
func _ping(): pass

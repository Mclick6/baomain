# server/server.gd
extends Node

const DEFAULT_PORT = 7777
var peer = ENetMultiplayerPeer.new()
var sessions = {} # {peer_id: Node with session data}

@onready var db_manager = $DatabaseManager

func _ready():
	print("--- Initializing Dedicated Server ---")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var error = peer.create_server(DEFAULT_PORT)
	if error != OK:
		print("ERROR: Failed to start server.")
		get_tree().quit()
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server listening on port %d." % DEFAULT_PORT)

func _on_peer_connected(id):
	print("SERVER: A client has connected! Peer ID: %d" % id)
	var new_session = Node.new()
	new_session.name = str(id)
	sessions[id] = new_session
	add_child(new_session)

func _on_peer_disconnected(id):
	print("Peer disconnected: %d" % id)
	if sessions.has(id):
		# CORRECTED: The get() function now has the correct argument.
		var username = sessions[id].get("username", "A player")
		sessions[id].queue_free()
		sessions.erase(id)
		_broadcast_chat_message("[Server] %s has disconnected." % username)

func _broadcast_chat_message(message: String):
	for peer_id in sessions:
		if sessions[peer_id].has("username"):
			rpc_id(peer_id, "_rpc_receive_chat_message", message)

# --- SERVER-SIDE RPC API ---
@rpc("call_remote", "reliable")
func _request_registration(username, password):
	var sender_id = multiplayer.get_remote_sender_id()
	print("Registration request from peer %d for user '%s'" % [sender_id, username])
	
	var result: Dictionary = db_manager.register_account(username, password)
	
	if result.get("success"):
		rpc_id(sender_id, "_rpc_registration_success")
	else:
		rpc_id(sender_id, "_rpc_registration_failure", result.get("reason", "Unknown error."))

@rpc("call_remote", "reliable")
func _request_login(username, password):
	var sender_id = multiplayer.get_remote_sender_id()
	print("Login request from peer %d for user '%s'" % [sender_id, username])
	
	var player_data: Dictionary = db_manager.login(username, password)

	if not player_data.is_empty():
		if sessions.has(sender_id):
			sessions[sender_id].set("username", username)
		
		rpc_id(sender_id, "_rpc_login_success", player_data)
		_broadcast_chat_message("[Server] %s has connected." % username)
	else:
		rpc_id(sender_id, "_rpc_login_failure", "Invalid credentials.")

@rpc("call_remote", "reliable")
func _request_chat_message(message_text):
	var sender_id = multiplayer.get_remote_sender_id()
	var username = "Guest"
	
	if sessions.has(sender_id) and sessions[sender_id].has("username"):
		username = sessions[sender_id].get("username")
	
	var formatted_message = "%s: %s" % [username, message_text]
	_broadcast_chat_message(formatted_message)

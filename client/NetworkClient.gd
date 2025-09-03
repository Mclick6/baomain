# global/NetworkClient.gd
extends Node

# Custom signals for the UI to connect to.
signal connected_to_server
signal connection_failed
signal login_success(player_data)
signal login_failure(reason)
signal registration_success
signal registration_failure(reason)
signal chat_message_received(message)

const SERVER_IP = "127.0.0.1"
const DEFAULT_PORT = 7777

# The peer object, stored as a member variable to prevent it from being
# garbage collected, which would close the connection.
var peer = ENetMultiplayerPeer.new()

func _ready():
	# Connect to Godot's built-in multiplayer signals.
	# When they fire, we emit our own custom signals for the UI.
	multiplayer.connected_to_server.connect(func():
		print("CLIENT: Built-in 'connected_to_server' signal received! Emitting custom signal.")
		connected_to_server.emit()
	)
	multiplayer.connection_failed.connect(func():
		print("CLIENT: Built-in 'connection_failed' signal received! Emitting custom signal.")
		connection_failed.emit()
	)

func connect_to_server():
	peer.create_client(SERVER_IP, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer

# --- Functions Called by the Client UI to Send Requests to the Server ---

func request_login(username, password):
	rpc("_request_login", username, password)

func request_registration(username, password):
	rpc("_request_registration", username, password)

func send_chat_message(message_text):
	rpc("_request_chat_message", message_text)

# --- Server-Side RPC Stubs (Required for Local Validation) ---
# These functions are empty on the client. Their only purpose is to have the
# @rpc annotation so that Godot's safety check passes before it sends the
# request to the server, where the real logic exists.

@rpc("call_remote", "reliable")
func _request_login(_username, _password):
	pass

@rpc("call_remote", "reliable")
func _request_registration(_username, _password):
	pass

@rpc("call_remote", "reliable")
func _request_chat_message(_message_text):
	pass

# --- Functions Called BY the Server ON This Client ---
# These functions receive responses from the server and emit signals.

@rpc("call_local", "reliable")
func _rpc_login_success(player_data):
	login_success.emit(player_data)

@rpc("call_local", "reliable")
func _rpc_login_failure(reason):
	login_failure.emit(reason)

@rpc("call_local", "reliable")
func _rpc_registration_success():
	registration_success.emit()

@rpc("call_local", "reliable")
func _rpc_registration_failure(reason):
	registration_failure.emit(reason)

@rpc("call_local", "reliable")
func _rpc_receive_chat_message(message):
	chat_message_received.emit(message)

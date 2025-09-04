# global/NetworkClient.gd
extends Node

signal login_success(player_data)
signal login_failure(reason)
signal chat_message_received(message)
signal connected_to_server
signal connection_failed

const SERVER_IP = "127.0.0.1" # Use your public IP for production
const DEFAULT_PORT = 7777

func _ready():
	multiplayer.connected_to_server.connect(func(): connected_to_server.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())

func connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer

# --- CLIENT-SIDE API FUNCTIONS ---
# These are the functions your UI will call.

func request_login(username, password):
	# CORRECT: Use rpc_id() to call the function on the server (peer_id = 1)
	rpc_id(1, "_request_login", username, password)

func send_chat_message(message_text):
	# CORRECT: Use rpc_id() to call the function on the server (peer_id = 1)
	rpc_id(1, "_request_chat_message", message_text)

# --- CLIENT-SIDE RPC RESPONSES ---
# These functions are called BY the server to give the client information.

@rpc("any_peer", "reliable")
func _rpc_login_success(player_data):
	login_success.emit(player_data)

@rpc("any_peer", "reliable")
func _rpc_login_failure(reason):
	login_failure.emit(reason)

@rpc("any_peer", "reliable")
func _rpc_receive_chat_message(message):
	chat_message_received.emit(message)

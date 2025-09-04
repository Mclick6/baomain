# global/NetworkClient.gd
extends Node

signal connected_to_server
signal connection_failed
signal login_success(player_data)
signal login_failure(reason)
signal registration_success
signal registration_failure(reason)
signal chat_message_received(message)

const SERVER_IP = "64.138.224.7"
const DEFAULT_PORT = 7777

var peer = ENetMultiplayerPeer.new()

func _ready():
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

# --- Functions Called by the Client UI to Send Requests ---
func request_login(username, password):
	rpc("_request_login", username, password)
func request_registration(username, password):
	rpc("_request_registration", username, password)
func send_chat_message(message_text):
	rpc("_request_chat_message", message_text)
func save_data_to_server(data: Dictionary):
	rpc("_request_save_data", data)

# --- Server-Side RPC Stubs (for checksum matching) ---
@rpc("call_remote", "reliable")
func _request_login(_username, _password): pass
@rpc("call_remote", "reliable")
func _request_registration(_username, _password): pass
@rpc("call_remote", "reliable")
func _request_chat_message(_message_text): pass
@rpc("call_remote", "reliable")
func _request_save_data(_player_data: Dictionary): pass
@rpc("call_remote")
func _pong(): pass

# --- Functions Called BY the Server ON This Client ---
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
@rpc("call_local", "reliable")
func _ping():
	rpc("_pong")

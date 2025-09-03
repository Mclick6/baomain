# global/NetworkClient.gd
extends Node

signal connected_to_server
signal connection_failed
signal login_success(player_data)
signal login_failure(reason)
signal registration_success
signal registration_failure(reason)
signal chat_message_received(message)

const SERVER_IP = "127.0.0.1"
const DEFAULT_PORT = 7777

func _ready():
	multiplayer.connected_to_server.connect(func(): connected_to_server.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())

func connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer

func request_login(username, password):
	rpc_id(1, "_request_login", username, password)

func request_registration(username, password):
	rpc_id(1, "_request_registration", username, password)

func send_chat_message(message_text):
	rpc_id(1, "_request_chat_message", message_text)

@rpc("any_peer", "reliable")
func _rpc_login_success(player_data):
	login_success.emit(player_data)

@rpc("any_peer", "reliable")
func _rpc_login_failure(reason):
	login_failure.emit(reason)

@rpc("any_peer", "reliable")
func _rpc_registration_success():
	registration_success.emit()

@rpc("any_peer", "reliable")
func _rpc_registration_failure(reason):
	registration_failure.emit(reason)

@rpc("any_peer", "reliable")
func _rpc_receive_chat_message(message):
	chat_message_received.emit(message)

# server/DatabaseManager.gd
extends Node

var db_connection = SQLite.new()
var db_mutex = Mutex.new()

func _ready():
	db_connection.path = "res://chao_haven.db"
	
	if not db_connection.open_db():
		print("DATABASE ERROR: Could not open SQLite database.")
		get_tree().quit()
		return
	
	print("SQLite database opened successfully.")
	_create_tables()

func _create_tables():
	db_mutex.lock()
	
	var accounts_query = "CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, created_at TEXT NOT NULL);"
	var player_data_query = "CREATE TABLE IF NOT EXISTS player_data (id INTEGER PRIMARY KEY, account_id INTEGER UNIQUE NOT NULL, rings INTEGER NOT NULL, inventory TEXT, FOREIGN KEY(account_id) REFERENCES accounts(id));"
	var chao_query = "CREATE TABLE IF NOT EXISTS chao (id INTEGER PRIMARY KEY, player_id INTEGER NOT NULL, chao_name TEXT NOT NULL, stats TEXT, FOREIGN KEY(player_id) REFERENCES player_data(id));"
	db_connection.query(accounts_query)
	db_connection.query(player_data_query)
	db_connection.query(chao_query)

	db_mutex.unlock()

func _hash_password(password: String) -> String:
	var hc = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(password.to_utf8_buffer())
	return hc.finish().hex_encode()

func register_account(username: String, password: String) -> Dictionary:
	db_mutex.lock()
	
	var result: Dictionary
	var check_query = "SELECT id FROM accounts WHERE username = ?;"
	if db_connection.query_with_bindings(check_query, [username]):
		if not db_connection.query_result.is_empty():
			result = {"success": false, "reason": "Username is already taken."}
		else:
			var password_hash = _hash_password(password)
			var insert_query = "INSERT INTO accounts (username, password_hash, created_at) VALUES (?, ?, datetime('now'));"
			if db_connection.query_with_bindings(insert_query, [username, password_hash]):
				var get_id_query = "SELECT id FROM accounts WHERE username = ?;"
				if db_connection.query_with_bindings(get_id_query, [username]):
					var new_account_id = db_connection.query_result[0]["id"]
					var default_inventory = {"egg": 1, "nut": 5, "ball": 0}
					var player_data_query = "INSERT INTO player_data (account_id, rings, inventory) VALUES (?, ?, ?);"
					db_connection.query_with_bindings(player_data_query, [new_account_id, 100, JSON.stringify(default_inventory)])
					result = {"success": true, "reason": "Registration successful."}
	
	if result.is_empty():
		result = {"success": false, "reason": "A database error occurred."}

	db_mutex.unlock()
	return result

func login(username: String, password: String) -> Dictionary:
	db_mutex.lock()
	
	var result: Dictionary
	var query = "SELECT id, password_hash FROM accounts WHERE username = ?;"
	if db_connection.query_with_bindings(query, [username]):
		var db_result = db_connection.query_result
		if not db_result.is_empty():
			var account_id = db_result[0]["id"]
			if db_result[0]["password_hash"] == _hash_password(password):
				var player_data = load_player_data(account_id)
				player_data["account_id"] = account_id
				player_data["chao_data"] = load_chao_data(account_id)
				result = player_data
	
	db_mutex.unlock()
	return result

func load_player_data(account_id: int) -> Dictionary:
	var query = "SELECT rings, inventory FROM player_data WHERE account_id = ?;"
	if db_connection.query_with_bindings(query, [account_id]):
		var result = db_connection.query_result
		if not result.is_empty():
			var player_data = result[0]
			player_data["inventory"] = JSON.parse_string(player_data["inventory"])
			return player_data
	return {}

func load_chao_data(account_id: int) -> Array:
	var chao_list = []
	var get_player_id_query = "SELECT id FROM player_data WHERE account_id = ?;"
	if db_connection.query_with_bindings(get_player_id_query, [account_id]):
		var result = db_connection.query_result
		if not result.is_empty():
			var player_id = result[0]["id"]
			var chao_query = "SELECT chao_name, stats FROM chao WHERE player_id = ?;"
			if db_connection.query_with_bindings(chao_query, [player_id]):
				for chao_row in db_connection.query_result:
					var chao_data = chao_row
					chao_data["stats"] = JSON.parse_string(chao_data["stats"])
					chao_list.append(chao_data)
	return chao_list

func save_player_data(account_id: int, data: Dictionary):
	db_mutex.lock()

	var rings = data.get("rings", 0)
	var inventory = data.get("inventory", {})
	var chao_list = data.get("chao_list", [])

	var player_update_query = "UPDATE player_data SET rings = ?, inventory = ? WHERE account_id = ?;"
	db_connection.query_with_bindings(player_update_query, [rings, JSON.stringify(inventory), account_id])

	var get_player_id_query = "SELECT id FROM player_data WHERE account_id = ?;"
	if db_connection.query_with_bindings(get_player_id_query, [account_id]):
		var result = db_connection.query_result
		if not result.is_empty():
			var player_id = result[0]["id"]
			var delete_chao_query = "DELETE FROM chao WHERE player_id = ?;"
			db_connection.query_with_bindings(delete_chao_query, [player_id])
			
			for chao_data in chao_list:
				var chao_insert_query = "INSERT INTO chao (player_id, chao_name, stats) VALUES (?, ?, ?);"
				var chao_name = chao_data.get("chao_name", "New Chao")
				var chao_stats = chao_data.get("stats", {})
				db_connection.query_with_bindings(chao_insert_query, [player_id, chao_name, JSON.stringify(chao_stats)])
		else:
			print("DATABASE ERROR: Could not find player to save chao for.")
	
	print("Saved data for account_id: %d" % account_id)
	
	db_mutex.unlock()

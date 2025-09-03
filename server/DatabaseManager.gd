# server/DatabaseManager.gd
extends Node

var db_connection = SQLite.new()

func _ready():
	# This path is relative to the executable. The file will be created if it doesn't exist.
	db_connection.path = "res://chao_haven.db"
	
	# Open the database file.
	if not db_connection.open_db():
		print("DATABASE ERROR: Could not open SQLite database.")
		get_tree().quit()
		return
	
	print("SQLite database opened successfully.")
	_create_tables()

func _create_tables():
	var accounts_query = "CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, created_at TEXT NOT NULL);"
	var player_data_query = "CREATE TABLE IF NOT EXISTS player_data (id INTEGER PRIMARY KEY, account_id INTEGER UNIQUE NOT NULL, rings INTEGER NOT NULL, inventory TEXT, FOREIGN KEY(account_id) REFERENCES accounts(id));"
	var chao_query = "CREATE TABLE IF NOT EXISTS chao (id INTEGER PRIMARY KEY, player_id INTEGER NOT NULL, chao_name TEXT NOT NULL, stats TEXT, FOREIGN KEY(player_id) REFERENCES player_data(id));"
	
	db_connection.query(accounts_query)
	db_connection.query(player_data_query)
	db_connection.query(chao_query)

func _hash_password(password: String) -> String:
	var hc = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(password.to_utf8_buffer())
	return hc.finish().hex_encode()

func register_account(username: String, password: String) -> Dictionary:
	var check_query = "SELECT id FROM accounts WHERE username = ?;"
	if db_connection.query_with_bindings(check_query, [username]):
		var result = db_connection.get_result()
		if not result.is_empty():
			return {"success": false, "reason": "Username is already taken."}

	# If we reach here, the username is available.
	var password_hash = _hash_password(password)
	var insert_query = "INSERT INTO accounts (username, password_hash, created_at) VALUES (?, ?, datetime('now'));"
	if db_connection.query_with_bindings(insert_query, [username, password_hash]):
		var get_id_query = "SELECT id FROM accounts WHERE username = ?;"
		if db_connection.query_with_bindings(get_id_query, [username]):
			var new_account_id = db_connection.get_result()[0]["id"]
			
			var default_inventory = {"egg": 1, "nut": 5, "ball": 0}
			var player_data_query = "INSERT INTO player_data (account_id, rings, inventory) VALUES (?, ?, ?);"
			db_connection.query_with_bindings(player_data_query, [new_account_id, 100, JSON.stringify(default_inventory)])
			
			return {"success": true, "reason": "Registration successful."}
	
	# If any query failed, return an error.
	return {"success": false, "reason": "A database error occurred."}

func login(username: String, password: String) -> Dictionary:
	var query = "SELECT id, password_hash FROM accounts WHERE username = ?;"
	if db_connection.query_with_bindings(query, [username]):
		var result = db_connection.get_result()
		if result.is_empty():
			print("Login failed: User '%s' not found." % username)
			return {}

		var account_id = result[0]["id"]
		var stored_hash = result[0]["password_hash"]

		if stored_hash != _hash_password(password):
			print("Login failed: Incorrect password for user '%s'." % username)
			return {}

		return load_player_data(account_id)
	
	return {} # Query failed

func load_player_data(account_id: int) -> Dictionary:
	var query = "SELECT rings, inventory FROM player_data WHERE account_id = ?;"
	if db_connection.query_with_bindings(query, [account_id]):
		var result = db_connection.get_result()
		if result.is_empty():
			return {}

		var player_data = result[0]
		player_data["inventory"] = JSON.parse_string(player_data["inventory"])
		return player_data
		
	return {} # Query failed

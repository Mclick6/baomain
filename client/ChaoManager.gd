extends Node

var chao_list: Array = []
var chao_counter: int = 0

# --- DATA MANAGEMENT ---

func get_chao_data(chao_name: String) -> Dictionary:
	for chao in chao_list:
		if chao.get("chao_name") == chao_name:
			return chao
	return {}

func update_chao_stat(chao_name: String, stat: String, value):
	var chao_data = get_chao_data(chao_name)
	if chao_data.is_empty(): return
	
	if chao_data["stats"].has(stat):
		# Handle stat progress/level dictionaries
		if chao_data["stats"][stat] is Dictionary:
			var stat_dict = chao_data["stats"][stat]
			stat_dict["progress"] += value
			
			# --- THIS IS THE FIX ---
			# While progress is 100 or more, level up and reduce progress.
			while stat_dict["progress"] >= 100.0:
				stat_dict["level"] += 1
				stat_dict["progress"] -= 100.0
				if ChatManager:
					var message = "Chao %s leveled up %s to Level %d!" % [chao_name, stat.capitalize(), stat_dict["level"]]
					ChatManager.add_chat_message(message)
			# ---------------------

		else: # Handle simple value stats like mood/belly
			chao_data["stats"][stat] = clamp(chao_data["stats"][stat] + value, 0.0, 100.0)

func create_and_add_new_chao(pos: Vector2) -> Dictionary:
	chao_counter += 1
	var new_chao = {
		"chao_name": "Chao %d" % chao_counter,
		"position": {"x": pos.x, "y": pos.y},
		"stats": {
			"swim": {"level": 0, "progress": 0.0}, "fly": {"level": 0, "progress": 0.0},
			"run": {"level": 0, "progress": 0.0}, "power": {"level": 0, "progress": 0.0},
			"stamina": {"level": 0, "progress": 0.0}, "belly": 100.0, "mood": 100.0
		}
	}
	chao_list.append(new_chao)
	return new_chao

func rename_chao(old_name: String, new_name: String):
	var chao_data = get_chao_data(old_name)
	if not chao_data.is_empty():
		chao_data["chao_name"] = new_name
		print("ChaoManager: Renamed '%s' to '%s'" % [old_name, new_name])

# --- SCENE MANAGEMENT ---
func spawn_chao_in_hub(hub_node):
	var chao_scene = preload("res://chao.tscn")
	if not chao_scene: return
	
	var chao_container = hub_node.get_node_or_null("ChaoContainer")
	if not chao_container: return
		
	for chao_data in chao_list:
		var chao = chao_scene.instantiate()
		chao.deserialize(chao_data)
		chao_container.add_child(chao)

func capture_chao_from_hub(_hub_node):
	pass

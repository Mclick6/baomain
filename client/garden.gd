extends Node2D

@onready var spawn_area = get_node_or_null("SpawnArea")
@onready var chao_container = get_node_or_null("ChaoContainer")
@onready var inventory_panel = get_node_or_null("UI/InventoryPanel")
@onready var chao_stats_panel = get_node_or_null("UI/ChaoStatsPanel")
@onready var inventory_items = get_node_or_null("UI/InventoryPanel/ScrollContainer/InventoryItems")
@onready var stats_tab_container = get_node_or_null("UI/ChaoStatsPanel/TabContainer")
@onready var button_container = get_node_or_null("UI/ButtonContainer")
var inventory_visible = false
var chao_stats_visible = false
var drag_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var current_chao_tab: String = ""
var chao_stat_labels: Dictionary = {}

func _ready():
	name = "Garden"
	add_to_group("hub")
	if not chao_container:
		chao_container = Node2D.new()
		chao_container.name = "ChaoContainer"
		chao_container.z_index = 0
		add_child(chao_container)
	if inventory_panel:
		inventory_panel.visible = false
	if chao_stats_panel:
		chao_stats_panel.visible = false
		chao_stats_panel.position = get_viewport_rect().size / 2 - chao_stats_panel.size / 2
	
	ChaoManager.spawn_chao_in_hub(self)
	_update_inventory_display()
	_create_chao_stat_tabs()
	
	var stats_timer = get_node_or_null("UI/ChaoStatsPanel/StatsUpdateTimer")
	if stats_timer and not stats_timer.is_connected("timeout", Callable(self, "_update_chao_stats_display")):
		stats_timer.timeout.connect(Callable(self, "_update_chao_stats_display"))
	if inventory_items and not inventory_items.is_connected("item_selected", Callable(self, "_on_inventory_item_selected")):
		inventory_items.item_selected.connect(Callable(self, "_on_inventory_item_selected"))
	if stats_tab_container and not stats_tab_container.is_connected("tab_changed", Callable(self, "_on_tab_changed")):
		stats_tab_container.tab_changed.connect(Callable(self, "_on_tab_changed"))

func _exit_tree():
	if has_node("/root/Global"):
		capture_chao_from_hub()

func capture_chao_from_hub():
	var chao_nodes = get_node_or_null("ChaoContainer").get_children()
	var chao_list_data = []
	for chao in chao_nodes:
		if chao.has_method("serialize"):
			chao_list_data.append(chao.serialize())

	# CORRECTED: Read from the live Global variables, not the stale player_data dict
	var full_save_data = {
		"rings": Global.rings,
		"inventory": Global.inventory,
		"chao_list": chao_list_data
	}
	
	print("CLIENT: Saving data to server...")
	Server.save_data_to_server(full_save_data)

func _on_tab_changed(tab_index: int):
	if stats_tab_container and tab_index >= 0 and tab_index < stats_tab_container.get_tab_count():
		var tab = stats_tab_container.get_child(tab_index)
		if tab:
			current_chao_tab = tab.name
			Global.selected_chao = tab.name

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if event.pressed and Global.selected_item != "" and _has_selected_item():
			if Global.selected_item == "ball":
				is_dragging = true
				drag_start_pos = mouse_pos
				get_viewport().set_input_as_handled()
			elif _is_position_in_spawn_area(mouse_pos):
				_place_selected_item(mouse_pos)
				get_viewport().set_input_as_handled()
		elif not event.pressed and is_dragging and Global.selected_item == "ball":
			is_dragging = false
			var direction = (mouse_pos - drag_start_pos).normalized()
			if _has_selected_item() and _is_position_in_spawn_area(mouse_pos):
				_place_ball_at_position(mouse_pos, direction)
				Global.inventory["ball"] -= 1
				Global.selected_item = "" # Reset selected item
				_update_inventory_display()
				get_viewport().set_input_as_handled()

func _has_selected_item() -> bool:
	var item = Global.selected_item
	return item != "" and Global.inventory.has(item) and Global.inventory[item] > 0

func _place_selected_item(pos: Vector2):
	var item = Global.selected_item
	if not _has_selected_item(): return
	var instance = null
	match item:
		"egg": instance = _place_egg_at_position(pos)
		"nut": instance = _place_nut_at_position(pos)
		_: return
	if instance:
		Global.inventory[item] -= 1
		Global.selected_item = "" # Reset selected item
		_update_inventory_display()

func _place_egg_at_position(pos: Vector2):
	var egg_scene = preload("res://egg.tscn")
	if egg_scene:
		var egg = egg_scene.instantiate()
		egg.position = pos
		chao_container.add_child(egg)
		egg.egg_hatched.connect(Callable(self, "_on_egg_hatched"))
		if ChatManager: ChatManager.add_chat_message("Egg placed! It will hatch soon. Click to help!")
		return egg
	return null

func _place_nut_at_position(pos: Vector2):
	var nut_scene = preload("res://nut.tscn")
	if nut_scene:
		var nut = nut_scene.instantiate()
		nut.position = pos
		chao_container.add_child(nut)
		return nut
	return null

func _place_ball_at_position(pos: Vector2, direction: Vector2):
	var ball_scene = preload("res://toy_ball.tscn")
	if ball_scene:
		var ball = ball_scene.instantiate()
		ball.position = pos
		chao_container.add_child(ball)
		if direction.length() > 0:
			ball.throw(direction)
		return ball
	return null

func _is_position_in_spawn_area(pos: Vector2) -> bool:
	if not spawn_area: return true
	var shape = spawn_area.get_node_or_null("CollisionShape2D")
	if not shape: return true
	var shape_rect = shape.shape.get_rect()
	var global_rect = Rect2(spawn_area.global_position - shape_rect.size / 2, shape_rect.size)
	return global_rect.has_point(pos)

func _on_egg_hatched(_ignored_data: Dictionary, pos: Vector2):
	var new_chao_data = ChaoManager.create_and_add_new_chao(pos)
	var chao_scene = preload("res://chao.tscn")
	var chao = chao_scene.instantiate()
	chao.deserialize(new_chao_data)
	chao_container.add_child(chao)
	
	_create_chao_stat_tabs()
	if ChatManager: ChatManager.add_chat_message("New Chao %s has hatched!" % new_chao_data["chao_name"])

func _update_inventory_display():
	if not inventory_items or not has_node("/root/Global"): return
	inventory_items.clear()
	for item in Global.inventory:
		var count = Global.inventory[item]
		if count > 0:
			inventory_items.add_item("%s: %d" % [item.capitalize(), count], null, true)

func _on_inventory_item_selected(index: int):
	if not inventory_items or not has_node("/root/Global"): return
	var item_text = inventory_items.get_item_text(index)
	var item_name = item_text.split(":")[0].to_lower()
	if Global.inventory.has(item_name) and Global.inventory[item_name] > 0:
		Global.selected_item = item_name
		Global.selected_chao = ""
		inventory_panel.visible = false
		inventory_visible = false
		if ChatManager: ChatManager.add_chat_message("Selected item: %s" % item_name.capitalize())

func _create_chao_stat_tabs():
	if not stats_tab_container: return
	for child in stats_tab_container.get_children():
		child.queue_free()
	chao_stat_labels.clear()

	for chao_data in ChaoManager.chao_list:
		var chao_name = chao_data.get("chao_name", "")
		if chao_name == "": continue

		var tab = VBoxContainer.new()
		tab.name = chao_name
		stats_tab_container.add_child(tab)
		stats_tab_container.set_tab_title(stats_tab_container.get_tab_count() - 1, chao_name)
		
		var name_edit = LineEdit.new()
		name_edit.text = chao_name
		name_edit.set_meta("old_chao_name", chao_name)
		name_edit.text_submitted.connect(Callable(self, "_on_chao_name_changed"))
		tab.add_child(name_edit)
		
		var select_button = Button.new()
		select_button.text = "Select This Chao"
		select_button.pressed.connect(_on_chao_selected.bind(chao_name))
		tab.add_child(select_button)

		chao_stat_labels[chao_name] = {}
		for stat_name in chao_data.get("stats", {}):
			var label = Label.new()
			label.name = stat_name.capitalize()
			tab.add_child(label)
			chao_stat_labels[chao_name][stat_name] = label
	
	_update_chao_stats_display()

func _update_chao_stats_display():
	if not chao_stats_panel or not chao_stats_panel.visible or not ChaoManager: return
	for chao_data in ChaoManager.chao_list:
		var chao_name = chao_data.get("chao_name", "")
		if chao_name == "" or not chao_stat_labels.has(chao_name): continue

		if chao_data.has("stats"):
			var stats = chao_data["stats"]
			for stat_name in stats:
				if chao_stat_labels[chao_name].has(stat_name):
					var label = chao_stat_labels[chao_name][stat_name]
					var stat_value = stats[stat_name]
					if stat_value is Dictionary:
						var level = stat_value.get("level", 0)
						var progress = stat_value.get("progress", 0.0)
						label.text = "%s: Level %d (%.1f%%)" % [stat_name.capitalize(), level, progress]
					else:
						label.text = "%s: %.1f" % [stat_name.capitalize(), stat_value]

func _on_chao_name_changed(new_name: String):
	var current_tab = stats_tab_container.get_current_tab_control()
	if not current_tab: return

	var line_edit = null
	for child in current_tab.get_children():
		if child is LineEdit:
			line_edit = child
			break
	if not line_edit: return

	var old_name = line_edit.get_meta("old_chao_name", "")

	if old_name != "" and new_name != old_name:
		var chao_node = get_tree().get_first_node_in_group("chao")
		for chao in get_tree().get_nodes_in_group("chao"):
			if chao.chao_name == old_name:
				chao_node = chao
				break
		if chao_node:
			ChaoManager.rename_chao(old_name, new_name)
			chao_node.chao_name = new_name
			Global.selected_chao = new_name
			_update_chao_stats_display()

			var tab_index = stats_tab_container.get_tab_idx_from_control(current_tab)
			if tab_index != -1:
				stats_tab_container.set_tab_title(tab_index, new_name)
	
	if line_edit:
		line_edit.set_meta("old_chao_name", new_name)

func _on_chao_selected(chao_name: String):
	Global.selected_chao = chao_name
	current_chao_tab = chao_name
	get_tree().call_group("chao", "set_highlight", false)
	for chao in chao_container.get_children():
		if chao.is_in_group("chao") and chao.get_chao_name() == chao_name:
			chao.set_highlight(true)
			break
	if ChatManager: ChatManager.add_chat_message("Selected Chao %s" % chao_name)
	_update_chao_stats_display()

func _on_store_button_pressed():
	get_tree().change_scene_to_file("res://store.tscn")

func _on_minigame_button_pressed():
	get_tree().change_scene_to_file("res://minigames.tscn")

func _on_hatch_egg_button_pressed():
	if Global.inventory.get("egg", 0) > 0:
		Global.selected_item = "egg"
		if ChatManager: ChatManager.add_chat_message("Click in the garden to place the egg!")
	else:
		if ChatManager: ChatManager.add_chat_message("No eggs in inventory!")

func _on_feed_button_pressed():
	if Global.inventory.get("nut", 0) > 0:
		Global.selected_item = "nut"
		if ChatManager: ChatManager.add_chat_message("Click in the garden to place the nut!")
	else:
		if ChatManager: ChatManager.add_chat_message("No nuts in inventory!")

func _on_inventory_button_pressed():
	inventory_visible = !inventory_visible
	inventory_panel.visible = inventory_visible
	if inventory_visible:
		_update_inventory_display()
		if ChatManager: ChatManager.add_chat_message("Inventory opened")
	else:
		if ChatManager: ChatManager.add_chat_message("Inventory closed")

func _on_chao_stats_button_pressed():
	chao_stats_visible = !chao_stats_visible
	chao_stats_panel.visible = chao_stats_visible
	if chao_stats_visible:
		_update_chao_stats_display()
		if ChatManager: ChatManager.add_chat_message("Chao stats panel opened")
	else:
		if ChatManager: ChatManager.add_chat_message("Chao stats panel closed")

func _on_school_button_pressed():
	get_tree().change_scene_to_file("res://school.tscn")

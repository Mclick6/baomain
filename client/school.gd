extends Node2D

@onready var chao_container = $ChaoContainer
@onready var chao_selection_panel = $UI/ChaoSelectionPanel
@onready var teacher_swim_overlay = $UI/TeacherSwimOverlay
@onready var nurse_overlay = $UI/NurseOverlay
@onready var teacher_swim_chao_list = $UI/TeacherSwimOverlay/ScrollContainer/ChaoList
@onready var nurse_chao_list = $UI/NurseOverlay/ScrollContainer/ChaoList
var selected_chao: String = ""

func _ready():
	add_to_group("hub")
	ChaoManager.spawn_chao_in_hub(self)
	if chao_selection_panel:
		chao_selection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_chao_lists()

func _on_teacher_swim_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		teacher_swim_overlay.visible = true
		nurse_overlay.visible = false
		chao_selection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_chao_lists()
		if ChatManager and is_instance_valid(ChatManager):
			ChatManager.add_chat_message("Clicked Swim Teacher")

func _on_nurse_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		nurse_overlay.visible = true
		teacher_swim_overlay.visible = false
		chao_selection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_chao_lists()
		if ChatManager and is_instance_valid(ChatManager):
			ChatManager.add_chat_message("Clicked Nurse")

func _update_chao_lists():
	if teacher_swim_chao_list:
		Utils.clear_children(teacher_swim_chao_list)
		for chao_data in ChaoManager.chao_list:
			var button = Button.new()
			button.text = chao_data["chao_name"]
			button.pressed.connect(_on_teacher_swim_chao_selected.bind(chao_data["chao_name"]))
			teacher_swim_chao_list.add_child(button)
	if nurse_chao_list:
		Utils.clear_children(nurse_chao_list)
		for chao_data in ChaoManager.chao_list:
			var button = Button.new()
			button.text = chao_data["chao_name"]
			button.pressed.connect(_on_nurse_chao_selected.bind(chao_data["chao_name"]))
			nurse_chao_list.add_child(button)

func _on_teacher_swim_chao_selected(chao_name: String):
	selected_chao = chao_name
	if ChatManager and is_instance_valid(ChatManager):
		ChatManager.add_chat_message("Selected Chao %s for swim training" % selected_chao)

func _on_nurse_chao_selected(chao_name: String):
	selected_chao = chao_name
	if ChatManager and is_instance_valid(ChatManager):
		ChatManager.add_chat_message("Selected Chao %s for healing" % selected_chao)

func _on_train_swim_pressed():
	if selected_chao == "":
		if ChatManager and is_instance_valid(ChatManager):
			ChatManager.add_chat_message("No Chao selected!")
		return
	_update_global_chao_stats_by_name(selected_chao, "swim", 10.0)
	_update_global_chao_stats_by_name(selected_chao, "belly", -5.0)
	
	if ChatManager and is_instance_valid(ChatManager):
		ChatManager.add_chat_message("Trained swim for Chao %s" % selected_chao)

	ChaoManager.save_to_file()
	teacher_swim_overlay.visible = false
	selected_chao = ""

func _on_heal_pressed():
	if selected_chao == "":
		if ChatManager and is_instance_valid(ChatManager):
			ChatManager.add_chat_message("No Chao selected!")
		return
		
	_update_global_chao_stats_by_name(selected_chao, "belly", 10.0)
	_update_global_chao_stats_by_name(selected_chao, "mood", 10.0)
	
	if ChatManager and is_instance_valid(ChatManager):
		ChatManager.add_chat_message("Healed Chao %s!" % selected_chao)

	ChaoManager.save_to_file()
	nurse_overlay.visible = false
	selected_chao = ""

func _update_global_chao_stats_by_name(chao_name: String, stat_name: String, value_change: float):
	for i in range(ChaoManager.chao_list.size()):
		if ChaoManager.chao_list[i]["chao_name"] == chao_name:
			var stats = ChaoManager.chao_list[i]["stats"]
			if stats.has(stat_name):
				if stats[stat_name] is Dictionary: # Handle leveled stats
					stats[stat_name]["progress"] += value_change
					while stats[stat_name]["progress"] >= 100.0:
						stats[stat_name]["level"] += 1
						stats[stat_name]["progress"] -= 100.0
						if ChatManager and is_instance_valid(ChatManager):
							ChatManager.add_chat_message("Chao %s leveled up %s to %d!" % [chao_name, stat_name.capitalize(), stats[stat_name]["level"]])
				else: # Handle simple stats
					stats[stat_name] = clamp(stats[stat_name] + value_change, 0.0, 100.0)
			ChaoManager.chao_list[i]["stats"] = stats
			break

func _on_back_button_pressed():
	ChaoManager.capture_chao_from_hub(self)
	get_tree().change_scene_to_file("res://garden.tscn")

func _exit_tree():
	ChaoManager.capture_chao_from_hub(self)

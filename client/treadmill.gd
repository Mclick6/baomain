extends Node2D

func _ready():
	add_to_group("treadmill")
	var area = get_node_or_null("Area2D")
	var collision = get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		print("Treadmill Area2D found at %s, z_index: %d" % [global_position, z_index])
	if area and not area.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
		area.input_event.connect(Callable(self, "_on_area_2d_input_event"))
		print("Treadmill: Connected input_event signal")

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not has_node("/root/Global"):
			print("Global singleton not found")
			return
		if Global.selected_chao == "":
			ChatManager.add_chat_message("Select a Chao first!")
			print("No Chao selected for treadmill")
			return
		var selected_chao = null
		var chao_container = get_tree().get_root().get_node_or_null("Garden/ChaoContainer")
		if chao_container:
			for chao in chao_container.get_children():
				if chao.is_in_group("chao") and chao.get_chao_name() == Global.selected_chao:
					selected_chao = chao
					break
		if selected_chao and selected_chao.has_method("move_to_treadmill"):
			selected_chao.move_to_treadmill(self)
			ChatManager.add_chat_message("Chao %s moving to treadmill!" % Global.selected_chao)
			print("Treadmill: Sent %s to move to treadmill" % Global.selected_chao)
		else:
			ChatManager.add_chat_message("Chao %s cannot use treadmill!" % Global.selected_chao)
			print("Treadmill: Failed to send %s to treadmill" % Global.selected_chao)
		get_viewport().set_input_as_handled()

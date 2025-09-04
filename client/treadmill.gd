extends Node2D

func _ready():
	add_to_group("treadmill")
	var area = get_node_or_null("Area2D")
	if area and not area.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
		area.input_event.connect(Callable(self, "_on_area_2d_input_event"))

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not has_node("/root/Global") or Global.selected_chao == "":
			ChatManager.add_chat_message("Select a Chao first!")
			return

		# --- REVISED SEARCH LOGIC ---
		# This now correctly finds the ChaoContainer within the current scene (the Garden)
		# instead of using a fragile, absolute path.
		var selected_chao_node = null
		var chao_container = owner.get_node_or_null("ChaoContainer")
		if chao_container:
			for chao in chao_container.get_children():
				if chao.is_in_group("chao") and chao.get_chao_name() == Global.selected_chao:
					selected_chao_node = chao
					break
		# --------------------------

		if selected_chao_node and selected_chao_node.has_method("move_to_treadmill"):
			selected_chao_node.move_to_treadmill(self)
			ChatManager.add_chat_message("Chao %s moving to treadmill!" % Global.selected_chao)
		else:
			ChatManager.add_chat_message("Chao %s cannot use treadmill!" % Global.selected_chao)

		get_viewport().set_input_as_handled()

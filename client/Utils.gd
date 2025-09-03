extends Node

func clear_children(node: Node):
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		child.queue_free()

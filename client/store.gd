extends Control  

@onready var rings_label = $VBoxContainer/RingsLabel  
@onready var buy_egg_button = $VBoxContainer/ScrollContainer/ItemList/BuyEgg  
@onready var buy_nut_button = $VBoxContainer/ScrollContainer/ItemList/BuyNut  
@onready var buy_ball_button = $VBoxContainer/ScrollContainer/ItemList/BuyBall  
@onready var back_button = $VBoxContainer/BackButton  

func _ready():  
	if rings_label:  
		rings_label.text = "Rings: %d" % Global.rings  
	
	if buy_egg_button and not buy_egg_button.is_connected("pressed", Callable(self, "_on_buy_egg_pressed")):  
		buy_egg_button.pressed.connect(Callable(self, "_on_buy_egg_pressed"))  
	
	if buy_nut_button and not buy_nut_button.is_connected("pressed", Callable(self, "_on_buy_nut_pressed")):  
		buy_nut_button.pressed.connect(Callable(self, "_on_buy_nut_pressed"))  
	
	if buy_ball_button and not buy_ball_button.is_connected("pressed", Callable(self, "_on_buy_ball_pressed")):  
		buy_ball_button.pressed.connect(Callable(self, "_on_buy_ball_pressed"))  
	
	if back_button and not back_button.is_connected("pressed", Callable(self, "_on_back_button_pressed")):  
		back_button.pressed.connect(Callable(self, "_on_back_button_pressed"))  

func _on_buy_egg_pressed():  
	var cost = 50  
	if Global.rings >= cost:  
		Global.rings -= cost  
		Global.inventory["egg"] = Global.inventory.get("egg", 0) + 1  
		if ChatManager: ChatManager.add_chat_message("Bought Egg for %d rings!" % cost)  
		if rings_label: rings_label.text = "Rings: %d" % Global.rings  
	else:  
		if ChatManager: ChatManager.add_chat_message("Not enough rings for Egg! Need %d, have %d" % [cost, Global.rings])  

func _on_buy_nut_pressed():  
	var cost = 20  
	if Global.rings >= cost:  
		Global.rings -= cost  
		Global.inventory["nut"] = Global.inventory.get("nut", 0) + 1  
		if ChatManager: ChatManager.add_chat_message("Bought Nut for %d rings!" % cost)  
		if rings_label: rings_label.text = "Rings: %d" % Global.rings  
	else:  
		if ChatManager: ChatManager.add_chat_message("Not enough rings for Nut! Need %d, have %d" % [cost, Global.rings])  

func _on_buy_ball_pressed():  
	var cost = 30  
	if Global.rings >= cost:  
		Global.rings -= cost  
		Global.inventory["ball"] = Global.inventory.get("ball", 0) + 1  
		if ChatManager: ChatManager.add_chat_message("Bought Ball for %d rings!" % cost)  
		if rings_label: rings_label.text = "Rings: %d" % Global.rings  
	else:  
		if ChatManager: ChatManager.add_chat_message("Not enough rings for Ball! Need %d, have %d" % [cost, Global.rings])  

func _on_back_button_pressed():  
	get_tree().change_scene_to_file("res://garden.tscn")

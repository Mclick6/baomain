extends Control

@onready var card_grid = $CardGrid
@onready var score_label = $UI/ScoreLabel
@onready var back_button = $UI/BackButton
var cards: Array[Button] = []
var card_values: Array[String] = []
var flipped_cards: Array[int] = []
var matched_pairs: int = 0
var score: int = 0
var rings_earned: int = 0
var game_started: bool = false
var symbols = ["🍎", "🍌", "🍓", "🥜", "🥚", "⚽", "🌟", "💎"]

func _ready():
	name = "MemoryMatch"
	add_to_group("hub")
	ChaoManager.capture_chao_from_hub(self)
	print("Memory Match game loaded")
	_setup_game()
	if back_button and not back_button.is_connected("pressed", _on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

func _setup_game():
	Utils.clear_children(card_grid)
	cards.clear()
	card_values.clear()
	flipped_cards.clear()
	matched_pairs = 0
	score = 0
	rings_earned = 0
	game_started = true
	card_grid.columns = 4
	var symbols_to_use = symbols.slice(0, 8)
	var all_values = symbols_to_use + symbols_to_use
	all_values.shuffle()
	for i in range(16):
		var card = Button.new()
		card.text = "?"
		card.custom_minimum_size = Vector2(80, 80)
		card.add_theme_font_size_override("font_size", 32)
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style_normal.corner_radius_top_left = 8
		style_normal.corner_radius_top_right = 8
		style_normal.corner_radius_bottom_left = 8
		style_normal.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("normal", style_normal)
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.3, 0.3, 0.8)
		style_hover.corner_radius_top_left = 8
		style_hover.corner_radius_top_right = 8
		style_hover.corner_radius_bottom_left = 8
		style_hover.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("hover", style_hover)
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		style_pressed.corner_radius_top_left = 8
		style_pressed.corner_radius_top_right = 8
		style_pressed.corner_radius_bottom_left = 8
		style_pressed.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("pressed", style_pressed)
		card.pressed.connect(_on_card_pressed.bind(i))
		card_grid.add_child(card)
		cards.append(card)
		card_values.append(all_values[i])
	_update_score_display()

func _on_card_pressed(card_index: int):
	if not game_started:
		return
	if card_index in flipped_cards:
		return
	if flipped_cards.size() >= 2:
		return
	_flip_card(card_index)
	flipped_cards.append(card_index)
	if flipped_cards.size() == 2:
		_check_match()

func _flip_card(card_index: int):
	var card = cards[card_index]
	card.text = card_values[card_index]
	var style_flipped = StyleBoxFlat.new()
	style_flipped.bg_color = Color(0.9, 0.9, 0.3, 0.8)
	style_flipped.corner_radius_top_left = 8
	style_flipped.corner_radius_top_right = 8
	style_flipped.corner_radius_bottom_left = 8
	style_flipped.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("normal", style_flipped)

func _check_match():
	await get_tree().create_timer(1.0).timeout
	var card1_index = flipped_cards[0]
	var card2_index = flipped_cards[1]
	if card_values[card1_index] == card_values[card2_index]:
		_handle_match(card1_index, card2_index)
	else:
		_flip_cards_back(card1_index, card2_index)
	flipped_cards.clear()

func _handle_match(card1_index: int, card2_index: int):
	score += 10
	rings_earned += 10
	matched_pairs += 1
	ChatManager.add_chat_message("Match found! +10 rings")
	var style_matched = StyleBoxFlat.new()
	style_matched.bg_color = Color(0.2, 0.8, 0.2, 0.8)
	style_matched.corner_radius_top_left = 8
	style_matched.corner_radius_top_right = 8
	style_matched.corner_radius_bottom_left = 8
	style_matched.corner_radius_bottom_right = 8
	cards[card1_index].add_theme_stylebox_override("normal", style_matched)
	cards[card2_index].add_theme_stylebox_override("normal", style_matched)
	cards[card1_index].disabled = true
	cards[card2_index].disabled = true
	_update_score_display()
	if matched_pairs >= 8:
		_game_complete()

func _flip_cards_back(card1_index: int, card2_index: int):
	cards[card1_index].text = "?"
	cards[card2_index].text = "?"
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	cards[card1_index].add_theme_stylebox_override("normal", style_normal)
	cards[card2_index].add_theme_stylebox_override("normal", style_normal)

func _update_score_display():
	if score_label:
		score_label.text = "[center]Score: %d\nPairs: %d/8\nRings: %d[/center]" % [score, matched_pairs, rings_earned]

func _game_complete():
	game_started = false
	rings_earned += 50
	if Global:
		Global.rings += rings_earned
	ChatManager.add_chat_message("Congratulations! You completed the memory game with a score of %d! +50 ring bonus" % score)
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.pressed.connect(_setup_game)
	$UI.add_child(restart_button)
	restart_button.position = Vector2(10, 100)
	var garden = get_tree().get_root().get_node_or_null("Garden")
	if garden:
		garden.update_inventory_ui()

func _on_back_pressed():
	if Global:
		Global.rings += rings_earned
	
	var garden = get_tree().get_root().get_node_or_null("Garden")
	if garden:
		garden.update_inventory_ui()
	var minigames_scene = load("res://minigames.tscn")
	if minigames_scene:
		get_tree().change_scene_to_packed(minigames_scene)
	else:
		ChatManager.add_chat_message("Failed to load minigames scene")

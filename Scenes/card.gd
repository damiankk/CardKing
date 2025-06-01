class_name Card
extends Control

const COLOR_RED = Color(1, 0, 0) # Using Color(1,0,0) for pure red
const COLOR_BLACK = Color(0, 0, 0) # Using Color(0,0,0) for pure black

# Variables to store the card's identity
var suit: int = -1 # 0=Clubs, 1=Diamonds, 2=Hearts, 3=Spades. -1 means unassigned.
var rank: int = -1 # 1=Ace, 2-10, 11=Jack, 12=Queen, 13=King. -1 means unassigned.

# References to our Label nodes (gets them when the node is ready)
#@onready var rank_label: Label = $RankLabel
#@onready var suit_label: Label = $SuitLabel

var is_face_up: bool = false

# Call this function to set the card's suit and rank
func set_card_data(new_suit: int, new_rank: int):
	suit = new_suit
	rank = new_rank
	update_display() # Update the labels based on the new data

# Updates the visual display (labels) based on suit and rank
func update_display():
	# 1. Determine Rank String
	var rank_string: String
	match rank:
		1: rank_string = "A"
		11: rank_string = "J"
		12: rank_string = "Q"
		13: rank_string = "K"
		_: rank_string = str(rank) # Handles 2-10
	# Use $RankLabel directly:
	$RankLabel.text = rank_string

	# 2. Determine Suit Symbol and Color
	var suit_symbol: String
	var current_color: Color
	match suit:
		0: # Clubs
			suit_symbol = "♣"
			current_color = COLOR_BLACK
		1: # Diamonds
			suit_symbol = "♦"
			current_color = COLOR_RED
		2: # Hearts
			suit_symbol = "♥"
			current_color = COLOR_RED
		3: # Spades
			suit_symbol = "♠"
			current_color = COLOR_BLACK
		_: # Handle invalid suit (optional)
			suit_symbol = "?"
			current_color = COLOR_BLACK
	# Use $SuitLabel directly:
	$SuitLabel.text = suit_symbol

	# 4. Apply Color (using code override)
	# Use $RankLabel and $SuitLabel directly:
	$RankLabel.add_theme_color_override("font_color", current_color)
	$SuitLabel.add_theme_color_override("font_color", current_color)

	# Example adjustment in update_display if Background is a Panel
	#print("my is_face_up is " + str(is_face_up))
	# Ensure labels are visible when face-up
	$RankLabel.visible = is_face_up
	$SuitLabel.visible = is_face_up

	# Set z_index values dynamically
	$Background.z_index = 0  # Background should be at the lowest level
	$RankLabel.z_index = 1   # Rank label above the background
	$SuitLabel.z_index = 1   # Suit label above the background
	if is_face_up:
		$Background.modulate = Color(1, 1, 1) # White background
	else:
		$Background.modulate = Color(0.5, 0.5, 0.5) # Gray background
func _ready():
	update_display()

# Returns a human-readable string description of the card
func get_card_description() -> String:
	# --- Determine Rank String ---
	var rank_string: String
	match rank:
		1: rank_string = "Ace"
		11: rank_string = "Jack"
		12: rank_string = "Queen"
		13: rank_string = "King"
		# Default case for ranks 2-10
		_: rank_string = str(rank)

	# --- Determine Suit String ---
	var suit_string: String
	match suit:
		0: suit_string = "Clubs"
		1: suit_string = "Diamonds"
		2: suit_string = "Hearts"
		3: suit_string = "Spades"
		# Default case for invalid suit
		_: suit_string = "Unknown Suit"

	# --- Combine and return ---
	return rank_string + " of " + suit_string

func set_face_up(face_up: bool):
	is_face_up = face_up
	update_display()

func set_interactive(interactive: bool):
	if interactive:
		self.mouse_filter = Control.MouseFilter.MOUSE_FILTER_STOP
	else:
		self.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE

signal card_clicked(card_instance)
func _gui_input(event: InputEvent):
	# Only process if this card is interactive (mouse_filter is STOP)
	if get_mouse_filter() == Control.MOUSE_FILTER_STOP and is_face_up:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Emit a signal when this card is clicked
			card_clicked.emit(self) 
			get_viewport().set_input_as_handled() # Optional: Stop event from propagating further

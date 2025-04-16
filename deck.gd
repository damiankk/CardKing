extends Node

const CardScene = preload("res://Scenes/card.tscn")

var deck_cards: Array = [] # An array to hold the 52 card instances
var tableau_areas: Array = [] # An array to hold all of TableauPileArea
const TABLEAU_Y_OFFSET = 30
var stock_pile_cards: Array = []
var waste_cards: Array = []

func _ready():
	print("Deck node is ready. Creating and shuffling deck...")
	create_deck()
	shuffle_deck()
	print("Deck finished setup. Card count: ", deck_cards.size())

	# --- Get references to Tableau Area nodes ---
	print("Getting Tableau area nodes...")
	tableau_areas.clear() # Good practice to clear before populating
	for i in range(7): # Loop 0 to 6, so pile number is i + 1
		var pile_number = i + 1
		var node_name = "TableauPileArea" + str(pile_number)
		var tableau_pile_node = get_parent().get_node(node_name)

		if tableau_pile_node:
			tableau_areas.append(tableau_pile_node) # Append the node found
			# print("Found and stored: ", node_name) # Optional confirmation print
		else:
			print("ERROR: Could not find node named '", node_name, "'")

	# Check if we got all 7 areas
	if tableau_areas.size() == 7:
		print("Successfully stored references to all 7 Tableau areas.")
	else:
		print("WARN: Did not find all 7 Tableau area nodes!")

	# --- Call the initial deal function ---
	deal_initial_tableau()
	# --- Deal remaining cards ---
	deal_stock()
	
func create_deck():
	deck_cards.clear() # Start with an empty array
	# Loop through suits (0=C, 1=D, 2=H, 3=S)
	for suit in range(4):
		# Loop through ranks (1=A, 2-10, 11=J, 12=Q, 13=K)
		for rank in range(1, 14):
			# Create an instance of our card scene blueprint
			var new_card = CardScene.instantiate()

			# IMPORTANT: The new_card instance currently only exists in memory.
			# It is NOT automatically added to our main scene visually.
			# If we wanted to see it immediately, we might use add_child(new_card),
			# but the Deck node itself usually doesn't display cards.

			# Tell the new card instance what suit and rank it is
			new_card.set_card_data(suit, rank)

			# Add the configured card instance to our deck array
			deck_cards.append(new_card)
	print("Finished creating 52 cards in memory.")
	
func shuffle_deck():
	deck_cards.shuffle()
	print("Deck array shuffled.")
	
# Removes and returns the last card from the deck array
func deal_one_card(cards_pile):
	if cards_pile.is_empty():
		print("WARN: Tried to deal from empty deck.")
		return null # Return null if no cards are left
	# pop_back() removes and returns the last element from the array
	return cards_pile.pop_back()
	
func deal_initial_tableau():
	for i in range(7):
		var tableau_area_node = tableau_areas[i]
		for j in range(i + 1):
			var dealt_card = deal_one_card(deck_cards)
			if dealt_card:
				tableau_area_node.add_child(dealt_card)
				dealt_card.position = Vector2(0, j * TABLEAU_Y_OFFSET)
				# Inside the 'if dealt_card:' block in deal_initial_tableau
				if j == i: # Is this the last card for this pile?
					print("Setting card (Pile ", i, ", Card ", j, ") FACE UP") # Debug print
					dealt_card.set_face_up(true)
				else: # This is a card that should be face down
					print("Setting card (Pile ", i, ", Card ", j, ") FACE DOWN") # Debug print
					dealt_card.set_face_up(false) # Explicitly set face down
			else:
				print("Deck ended unexpectedly...")

func deal_stock():
	var stock_area = get_parent().get_node("StockPileArea")
	if not stock_area:
		print ("Dupa, nie znalazl")
	else:
		while(!deck_cards.is_empty()):
			var dealt_card = deal_one_card(deck_cards)
			if dealt_card:
				stock_pile_cards.append(dealt_card)
				stock_area.add_child(dealt_card)
				dealt_card.position = Vector2.ZERO #concise way to set Vector2(0,0)


func _on_stock_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			print("Stock pile clicked!")
			var waste_area_node = get_parent().get_node("WastePileArea")
			var stock_area = get_parent().get_node("StockPileArea")
			if stock_pile_cards.is_empty(): 
				print("Empty stock_pile_cards array. Trying to restock")
				if waste_cards.is_empty():
					return
				else:
					print("Restocking from waste cards")
					while not waste_cards.is_empty():
						var restocked_card = waste_cards.pop_back()
						waste_area_node.remove_child(restocked_card)
						restocked_card.visible = true
						restocked_card.set_face_up(false)
						stock_pile_cards.append(restocked_card)
						stock_area.add_child(restocked_card)
						restocked_card.position = Vector2.ZERO
			else:
				var dealt_card = deal_one_card(stock_pile_cards)
				if dealt_card:
					# --- Remove card from the previous parent ---
					var old_parent = dealt_card.get_parent()
					if old_parent:
						old_parent.remove_child(dealt_card)

					# -- Hiding all previous cards on waste_area_node --
					var waste_area_node_children = waste_area_node.get_children()
					for child in waste_area_node_children:
						child.visible = false

					print("Adding card to waste_area_node")
					dealt_card.set_face_up(true)
					waste_cards.append(dealt_card)
					waste_area_node.add_child(dealt_card)
					dealt_card.position = Vector2.ZERO

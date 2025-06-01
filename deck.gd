extends Node

const CardScene = preload("res://Scenes/card.tscn")

var deck_cards: Array = [] # An array to hold the 52 card instances
var tableau_areas: Array = [] # An array to hold all of TableauPileArea
var tableau_piles: Array = [[], [], [], [], [], [], []] # An array to hold all cards within all TableauPileArea Piles - game state data - logical representation!!
var foundation_areas: Array = [] # An array to hold all of FoundationPileArea
var foundation_piles: Array = [[], [], [], []] # We need a way to store which cards are in each foundation pile. An array containing four other empty arrays is a good way to represent this.
const TABLEAU_Y_OFFSET = 30
var stock_pile_cards: Array = []
var waste_cards: Array = []

var selected_card: Card = null
var source_pile_type: String = "" # Will be "WASTE" or "TABLEAU"
var source_pile_idx: int = -1    # Index if source is Tableau (0-6), or -1/other for Waste
var selected_stack: Array = []   # For now, will just hold [selected_card]

#Initializes everything – creates the full deck, shuffles it, gets references to the pile areas, and calls deal_initial_tableau() and deal_stock().
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

	foundation_areas.clear()
	for i in range(4):
		var pile_number = i + 1
		var node_name = "FoundationPileArea" + str(pile_number)
		var foundation_pile_node = get_parent().get_node(node_name)
		
		if foundation_pile_node:
			foundation_areas.append(foundation_pile_node)
		else:
			print("ERROR: Could not find node named '", node_name, "'")
			
	if foundation_areas.size() == 4:
		print("Successfully stored references to all 4 Foundation areas.")
	else:
		print("WARN: Did not find all 4 Foundation area nodes!")
		
	# --- Call the initial deal function ---
	deal_initial_tableau()
	# --- Deal remaining cards ---
	deal_stock()
	
#create_deck(): Instantiates 52 Card scenes, sets their data, and adds them to deck_cards
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
			# --- Connect the signal ONCE when the card is created ---
			new_card.card_clicked.connect(_on_playable_card_clicked)
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
	
# Deals cards from deck_cards to the tableau_areas, setting the last card in each pile face-up.
func deal_initial_tableau():
	for i in range(7):
		var tableau_area_node = tableau_areas[i]
		for j in range(i + 1):
			var dealt_card = deal_one_card(deck_cards)
			if dealt_card:
				tableau_area_node.add_child(dealt_card)
				tableau_piles[i].append(dealt_card)
				dealt_card.position = Vector2(0, j * TABLEAU_Y_OFFSET)
				# Inside the 'if dealt_card:' block in deal_initial_tableau
				if j == i: # Is this the last card for this pile?
					print("Setting card (Pile ", i, ", Card ", j, ") FACE UP") # Debug print
					dealt_card.set_face_up(true)
					dealt_card.set_interactive(true)
				else: # This is a card that should be face down
					#print("Setting card (Pile ", i, ", Card ", j, ") FACE DOWN") # Debug print
					dealt_card.set_face_up(false) # Explicitly set face down
			else:
				print("Deck ended unexpectedly...")

# Deals remaining cards from deck_cards to StockPileArea (visually) and stock_pile_cards (data), face-down.
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

# Handles clicks on the stock pile – deals a card from stock_pile_cards to waste_cards (face-up, visually to WastePileArea), or recycles waste_cards back to stock_pile_cards if stock is empty.
func _on_stock_pile_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			deselect_selected_card()
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
						restocked_card.set_interactive(false)
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
					dealt_card.set_interactive(true)
					waste_cards.append(dealt_card)
					waste_area_node.add_child(dealt_card)
					dealt_card.position = Vector2.ZERO

# Before we can actually move cards to the foundations, we need a function that checks if a card can be legally placed on a specific foundation pile. This function will be crucial later when we implement card dragging or clicking to move.
#card_to_add: This will be a reference to a Card node instance that we're trying to place.
# foundation_index: An integer (0 to 3) indicating which of the four foundation piles we're trying to place it on.
# It should return true if the move is legal, and false otherwise.
func can_add_to_foundation(card_to_add: Card, foundation_index: int) -> bool:
	var foundation_area_cards : Array = foundation_piles[foundation_index]
	if foundation_area_cards.is_empty():
		if card_to_add.rank == 1:
			return true
		else:
			return false
	else:
		# check what rank is on top already
		var top_card_on_foundation : Card = foundation_area_cards.back()
		if card_to_add.rank == (top_card_on_foundation.rank + 1) && card_to_add.suit == top_card_on_foundation.suit:
			return true
		else:
			return false


#card_node: The Card instance we want to add.
#foundation_idx: Which foundation pile (0-3) to add it to.
func add_card_to_foundation(card_node: Card, foundation_idx: int):
	var foundation_area : Panel = foundation_areas[foundation_idx]
	var foundation_area_children = foundation_area.get_children()
	
	card_node.set_face_up(true)
	card_node.visible = true
	
	for child in foundation_area_children:
		child.visible = false
	
	foundation_area.add_child(card_node)
	card_node.position = Vector2.ZERO
	foundation_piles[foundation_idx].append(card_node)
	
func _on_foundation_area_clicked(event: InputEvent, foundation_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if selected_card != null:
				if can_add_to_foundation(selected_card, foundation_idx):
					_execute_move("FOUNDATION", foundation_idx)
				else:
					print("Illegal move for selected card to Foundation")
					deselect_selected_card()
				return
			else:
				if not waste_cards.is_empty():
					var top_waste_card : Card = waste_cards.back()
					
					if can_add_to_foundation(top_waste_card, foundation_idx):
						waste_cards.pop_back()
						var waste_area_node = get_parent().get_node("WastePileArea")
						
						if not waste_area_node:
							print("waste_area_node not found")
						
						waste_area_node.remove_child(top_waste_card)
						add_card_to_foundation(top_waste_card, foundation_idx)
						
						if not waste_cards.is_empty():
							var new_top_waste_card : Card = waste_cards.back()
							new_top_waste_card.visible = true
							
					return


func flip_top_tableau_card(tableau_idx: int):
	if tableau_piles[tableau_idx].is_empty():
		return

	var top_card : Card = tableau_piles[tableau_idx].back()
	top_card.set_face_up(true)
	top_card.set_interactive(true)


func can_add_to_tableau(card_to_move: Card, tableau_idx: int) -> bool:
	if tableau_piles[tableau_idx].is_empty():
		if card_to_move.rank == 13:
			return true
		else:
			return false # Explicitly false if not a King on empty
	else:
		var top_card : Card = tableau_piles[tableau_idx].back()
		if card_to_move.rank + 1 == top_card.rank:
			if (card_to_move.suit in [1,2] && top_card.suit in [0,3]) || (card_to_move.suit in [0,3] && top_card.suit in [1,2]):
				return true
			else:
				return false # Colors are not alternating
		else:
			return false # Rank is not one lower
	return false # Should ideally not be reached if logic above is exhaustive


func add_card_to_tableau(card_to_move: Card, tableau_idx: int):
	# get number of cards in tableau
	var number_of_cards = len(tableau_piles[tableau_idx])
	
	var tableau_area : Panel = tableau_areas[tableau_idx]
	# add visual representation of the card
	card_to_move.set_face_up(true)
	card_to_move.position = Vector2(0, number_of_cards * TABLEAU_Y_OFFSET)
	card_to_move.z_index = number_of_cards
	
	tableau_area.add_child(card_to_move)
	
	# add card to the list
	tableau_piles[tableau_idx].append(card_to_move)


func _on_tableau_pile_area_gui_input(event: InputEvent, tableau_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			
			# --- PRIORITY 1: A card IS ALREADY SELECTED ---
			if selected_card != null:
				print("Tableau area ", tableau_idx, " clicked with card selected: ", selected_card.get_card_description())
				if can_add_to_tableau(selected_card, tableau_idx):
					_execute_move("TABLEAU", tableau_idx) # This handles deselection
				else:
					print("Illegal move of selected card to Tableau pile ", tableau_idx)
					deselect_selected_card() # Deselect on failed attempt
				return # Action for this click is complete

			# --- PRIORITY 2: NO card selected, try an "automatic" move from Waste ---
			print("Tableau area ", tableau_idx, " clicked with NO card selected. Trying Waste.")
			if not waste_cards.is_empty():
				var top_waste_card : Card = waste_cards.back() 
				if can_add_to_tableau(top_waste_card, tableau_idx):
					# Perform Waste-to-Tableau move (card was not "selected" by player first)
					waste_cards.pop_back()
					var waste_area_node = get_parent().get_node("WastePileArea")
					if not waste_area_node:
						print("ERROR: waste_area_node not found for auto-move W->T")
						waste_cards.append(top_waste_card) # Put card back
						return
					
					if top_waste_card.get_parent() == waste_area_node:
						waste_area_node.remove_child(top_waste_card)
					
					add_card_to_tableau(top_waste_card, tableau_idx)
					
					if not waste_cards.is_empty():
						var new_top_waste_card : Card = waste_cards.back()
						new_top_waste_card.visible = true
						new_top_waste_card.set_interactive(true)
					print("Auto-moved ", top_waste_card.get_card_description(), " from Waste to Tableau ", tableau_idx)
					return
			
			print("No selected card, and no valid auto-move from Waste to Tableau ", tableau_idx, " possible.")
			
func deselect_selected_card():
	if selected_card == null:
		return
	
	for card_in_stack in selected_stack:
		card_in_stack.modulate = Color.WHITE
	selected_card = null
	source_pile_type = ""
	source_pile_idx = -1
	selected_stack = []

func select_card(clicked_card: Card, clicked_card_pile_info: Dictionary):
	source_pile_type = clicked_card_pile_info.type
	source_pile_idx = clicked_card_pile_info.pile_idx
	selected_card = clicked_card
	
	if source_pile_type == "TABLEAU":
		var card_idx_within_data_pile = tableau_piles[source_pile_idx].find(clicked_card)
		if card_idx_within_data_pile == -1 or not clicked_card.is_face_up:
			print("Invalid card clicked")
			deselect_selected_card()
			return
		selected_stack = tableau_piles[source_pile_idx].slice(card_idx_within_data_pile)
	else:
		selected_stack = [clicked_card]
		
	for card_in_stack in selected_stack:
		card_in_stack.modulate = Color.LIGHT_BLUE
	print("Selected: ", clicked_card.get_card_description())

func _on_playable_card_clicked(clicked_card: Card):
	var clicked_card_pile_info = _get_card_pile_info(clicked_card) # Info for the card just clicked

	if clicked_card_pile_info == null:
		print("Clicked card (", clicked_card.get_card_description(), ") is not a recognized top-of-pile. Deselecting if anything was selected.")
		if selected_card: # If a card was selected, and user clicked an invalid spot
			deselect_selected_card()
		return
			
	# At this point, clicked_card_pile_info is valid (clicked_card is a top-of-pile)

	if selected_card == null:
		# No card was previously selected, so select this clicked_card as the source.
		select_card(clicked_card, clicked_card_pile_info)
		return 
	elif selected_card == clicked_card:
		# Clicked the SAME card that was already selected: Deselect it.
		deselect_selected_card()
		return 
	else: # A card IS selected (selected_card), and a DIFFERENT (valid top-of-pile) card is clicked.
		  # selected_card is the SOURCE.
		  # clicked_card (and its clicked_card_pile_info) is the DESTINATION.
		
		var move_attempted_and_resolved = false

		if clicked_card_pile_info.type == "TABLEAU":
			if can_add_to_tableau(selected_card, clicked_card_pile_info.pile_idx):
				_execute_move("TABLEAU", clicked_card_pile_info.pile_idx) # This calls deselect_selected_card
			else:
				print("Cannot add selected card to target Tableau pile.")
				deselect_selected_card() # Deselect if move to this specific target is illegal
			move_attempted_and_resolved = true
		elif clicked_card_pile_info.type == "FOUNDATION":
			if can_add_to_foundation(selected_card, clicked_card_pile_info.pile_idx):
				_execute_move("FOUNDATION", clicked_card_pile_info.pile_idx) # This calls deselect_selected_card
			else:
				print("Cannot add selected card to target Foundation pile.")
				deselect_selected_card() # Deselect if move to this specific target is illegal
			move_attempted_and_resolved = true
		
		if not move_attempted_and_resolved:
			# Clicked card was a valid top-of-pile, but not a valid Tableau/Foundation destination
			# for the currently selected_card. So, deselect old, select new.
			print("Target was not a valid Tableau/Foundation for selected card. Switching selection.")
			deselect_selected_card()
			select_card(clicked_card, clicked_card_pile_info) # Select the newly clicked card as a new source
		
		return # Action complete for this click

func _get_card_pile_info(card_node: Card):
	if not waste_cards.is_empty() and waste_cards.back() == card_node:
		return {"type": "WASTE", "pile_idx": -1}

	for i in range(tableau_piles.size()):
		var pile_cards : Array = tableau_piles[i]
		if card_node in pile_cards: # Or iterate to find exact card and its position
			return {"type": "TABLEAU", "pile_idx": i}

	for i in range(foundation_piles.size()):
		var pile_cards : Array = foundation_piles[i]
		if card_node in pile_cards: # Or iterate to find exact card and its position
			return {"type": "FOUNDATION", "pile_idx": i}
	return

func _execute_move(destination_type: String, destination_idx: int):
	var card_to_move : Card = selected_card
	if not card_to_move: 
		return
	# first remove card from current source
	if source_pile_type == "WASTE":
		var waste_area_node = get_parent().get_node("WastePileArea")
		if not waste_area_node:
			print("waste_area_node not found")
			return
		waste_cards.pop_back()
		waste_area_node.remove_child(card_to_move)
		if waste_cards.is_empty():
			print("waste_cards array is empty")
		else:
			print("Update waste visuals")
			var restocked_card = waste_cards.back()
			restocked_card.visible = true
			restocked_card.set_interactive(true)
	elif source_pile_type == "TABLEAU":
		var source_tableau_area_node = tableau_areas[source_pile_idx]
		if card_to_move in source_tableau_area_node.get_children():
			var stack_size = selected_stack.size()
			for card_in_stack in selected_stack:
				if not tableau_piles[source_pile_idx].is_empty():
					tableau_piles[source_pile_idx].pop_back()
				if source_tableau_area_node and card_in_stack.get_parent() == source_tableau_area_node:
					source_tableau_area_node.remove_child(card_in_stack)
		flip_top_tableau_card(source_pile_idx)
	else:
		print("Invalid source_pile_type variable")
		deselect_selected_card()
		return
		
	# add cards to destination
	if destination_type == "TABLEAU":
		for card_in_stack in selected_stack:
			add_card_to_tableau(card_in_stack, destination_idx)
	elif destination_type == "FOUNDATION":
		add_card_to_foundation(card_to_move, destination_idx)
	else:
		print("Invalid destination type variable")
		deselect_selected_card()
		return
	
	deselect_selected_card()
	

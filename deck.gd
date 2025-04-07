extends Node

const CardScene = preload("res://Scenes/card.tscn")

var deck_cards: Array = [] # An array to hold the 52 card instances

func _ready():
	print("Deck node is ready. Creating and shuffling deck...")
	create_deck()
	shuffle_deck()
	print("Deck finished setup. Card count: ", deck_cards.size())

	# --- Deal one card visually to the StockPileArea ---
	# Get a reference to the StockPileArea node (which is a sibling)
	# get_parent() gets 'Main', then get_node finds 'StockPileArea'
	var stock_area = get_parent().get_node("StockPileArea")

	if stock_area: # Check if we successfully found the node
		var card_to_deal = deal_one_card() # Get one card from our array
		if card_to_deal: # Check we actually got a card (deck wasn't empty)
			# Set the card's position relative to its new parent (stock_area)
			# Vector2(0, 0) means the top-left corner of the stock_area panel
			card_to_deal.position = Vector2(0, 0)

			# Add the card instance as a child of stock_area
			# This makes the card VISIBLE and part of the scene tree!
			stock_area.add_child(card_to_deal)

# Call the new function to get the description string
			print("Dealt one card (", card_to_deal.get_card_description(), ") to stock area visually.")
		else:
			print("Deck was empty, couldn't deal test card.")
	else:
		# This error means the node name in get_node() might be wrong
		# or the Deck node isn't a direct child of Main.
		print("ERROR: Could not find StockPileArea node relative to Deck node.")
	
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
func deal_one_card():
	if deck_cards.is_empty():
		print("WARN: Tried to deal from empty deck.")
		return null # Return null if no cards are left
	# pop_back() removes and returns the last element from the array
	return deck_cards.pop_back()

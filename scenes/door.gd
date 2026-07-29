extends Area2D

func _ready() -> void:
	# Look at the Inspector for this node and set:
	# Collision -> Layer: Leave Empty
	# Collision -> Mask: Check Box 2 (Player Hurtbox) or Box 1 (wherever player body is)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if the node entering the door is your player
	if body.is_in_group("player"):
		print("Door: Player entered! Changing rooms...")
		
		# 1. Clear out the player reference before changing scenes to prevent enemy crashes
		GameManager.unregister_player(body)
		
		# 2. Tell the Room Manager to pick a random map and launch it!
		Roommanger.load_next_random_room()

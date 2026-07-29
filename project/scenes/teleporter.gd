extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.unregister_player(body) # Clean up old player reference
		Roommanger.load_next_room()        # Roll into the progression tracker!

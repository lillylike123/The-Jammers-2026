extends Area2D

var is_locked: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	modulate.a = 0.3 

func unlock_door() -> void:
	is_locked = false
	modulate.a = 1.0 
	print("Exit Door: The path forward is unlocked!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if is_locked:
			print("Exit Door: It's locked! You must defeat the boss first.")
			return 
			
		print("Exit Door: Transitioning to the final area...")
		GameManager.unregister_player(body)
		
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")

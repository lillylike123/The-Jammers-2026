extends Node2D

@onready var boss = $"Statue Boss"
@onready var exit_door = $Door 

func _ready() -> void:
	if boss and boss.has_signal("died"):
		boss.died.connect(_on_boss_defeated)
	else:
		push_warning("Boss Room Controller: Boss node or died signal not found!")

func _on_boss_defeated() -> void:
	print("Boss Room Controller: Boss defeated signal caught!")
	
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(exit_door):
			exit_door.unlock_door()
	)

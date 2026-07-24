extends Node2D
@onready var start: Button=$Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start.pressed.connect(move_to_weapon_select)

func move_to_weapon_select():
	get_tree().change_scene_to_file("res://the-jammers-2026-main/weapon_select.tscn")



# Called every frame. 'delta' is the elapsed time since the previous frame.

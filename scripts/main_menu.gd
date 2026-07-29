extends Node2D
@onready var start: Button=$Button
@onready var Settings: Button = $Button2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start.pressed.connect(move_to_weapon_select)
	Settings.pressed.connect(move_to_settings)

func move_to_weapon_select():
	get_tree().change_scene_to_file("res://scenes/weapon_select.tscn")
	
func move_to_settings():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_main_menu_button_pressed() -> void:
	HealthBar.hide_and_reset_hud() 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")



# Called every frame. 'delta' is the elapsed time since the previous frame.

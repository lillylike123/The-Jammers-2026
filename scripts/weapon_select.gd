extends Node2D
@onready var sword: Button=$Button
@onready var bow: Button=$Button2
@onready var sword_2:VBoxContainer=$CenterContainer4/VBoxContainer/PanelContainer/VBoxContainer
@onready var bow_2:VBoxContainer=$CenterContainer6/VBoxContainer/PanelContainer/VBoxContainer
@onready var sprite: AnimatedSprite2D=$AnimatedSprite2D
@onready var Back: Button = $Button3

func _ready() -> void:
	Music.play_music(Music.MENU)
	sprite.play("default")
	sword.mouse_entered.connect(func(): sprite.play("sword"))
	sword_2.mouse_entered.connect(func(): sprite.play("sword"))
	bow.mouse_entered.connect(func(): sprite.play("bow"))
	sword.mouse_exited.connect(_check_reset)
	bow.mouse_exited.connect(_check_reset)
	sword_2.mouse_exited.connect(_check_reset)
	bow_2.mouse_entered.connect(func(): sprite.play("bow"))
	bow_2.mouse_exited.connect(_check_reset)
	Back.pressed.connect(move_to_main_menu)
	sword.pressed.connect(_on_button_pressed)
	bow.pressed.connect(_on_button_2_pressed)
	
func move_to_main_menu():
	pass
	
func _check_reset() -> void:
	await get_tree().process_frame
	if not sword.is_hovered() and not bow.is_hovered():
		sprite.play("default")
		
func _on_button_pressed() -> void:
	GameManager.set_weapon(GameManager.Weapon.SWORD)
	_start_game()
	
func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/startroom.tscn")
	HealthBar.start_hud()

func _on_button_2_pressed() -> void:
	GameManager.set_weapon(GameManager.Weapon.BOW)
	_start_game()

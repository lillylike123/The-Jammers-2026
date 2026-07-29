extends Node2D

@onready var M_slider: HSlider = $HSlider
@onready var M_value: Label = $Label5
@onready var Back: Button = $Button


@export var bus_name: String = "Master" 
var bus_index: int = 0

func _ready() -> void:
	Music.play_music(Music.MENU)
	bus_index = AudioServer.get_bus_index(bus_name)
	var M_current_db: float = AudioServer.get_bus_volume_db(bus_index)
	M_slider.value = db_to_linear(M_current_db)
	update_label(M_slider.value)
	M_slider.value_changed.connect(when_changed)
	Back.pressed.connect(move_to_main_menu)

func move_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func when_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(new_value))
	
	AudioServer.set_bus_mute(bus_index, new_value == 0.0)
	
	update_label(new_value)

func update_label(value: float) -> void:
	if M_value:
		M_value.text = str(round(value)) + "%"

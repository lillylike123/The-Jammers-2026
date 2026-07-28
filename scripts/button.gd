extends Button

const dialogues: Array[String] = [
	"You've been spending weeks on the streets trying to collect money to tend to your ill grandmother, but as days pass by, the possibility of saving her worsens.
														   (Press to continue)",
	"Suddenly, one day you are greeted by a mysterious man who shares with you information about a secret dungeon.
														   (Press to continue)",
	"In this said dungeon is a golden tome that will be able to heal your grandmother's almost uncurable illness.
														   (Press to continue)",
	"Like the determined grandchild you are; you venture through the dungeon, defeating countless enemies and taking your sweet time learning swordsmanship.
														   (Press to continue)",
	"You are finally met with the last boss and are ready to save your grandmother and leave this dungeon once and for all
														   (Press to continue)"
	]
@onready var index: int= 0
func _ready() -> void:
	text=dialogues[index]
	

func _on_pressed() -> void:
	index+=1
	if index>4:
		get_tree().change_scene_to_file("res://scenes/startroom.tscn")
	else: 
		text=dialogues[index]

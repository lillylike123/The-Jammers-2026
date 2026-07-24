extends Node2D
@onready var sword: Button=$Button
@onready var bow: Button=$Button2
@onready var sprite: AnimatedSprite2D=$AnimatedSprite2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play("default")
	sword.mouse_entered.connect(func(): sprite.play("sword"))
	bow.mouse_entered.connect(func(): sprite.play("bow"))
	sword.mouse_exited.connect(_check_reset)
	bow.mouse_exited.connect(_check_reset)

func _check_reset() -> void:
	await get_tree().process_frame
	if not sword.is_hovered() and not bow.is_hovered():
		sprite.play("default")

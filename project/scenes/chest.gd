extends Area2D

@export var item_id: String = "gold"
@export var item_amount: int = 25

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_already_opened: bool = false
var player_nearby: bool = false

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("closed")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(incoming_node: Node2D) -> void:
	if incoming_node.is_in_group("player"):
		player_nearby = true

func _on_body_exited(incoming_node: Node2D) -> void:
	if incoming_node.is_in_group("player"):
		player_nearby = false

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("MOUSE CLICK DETECTED ON CHEST! Nearby status: ", player_nearby) 
		if player_nearby and not is_already_opened:
			_open_chest()

func _open_chest() -> void:
	is_already_opened = true
	print("Chest successfully opened!")
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("open"):
		animated_sprite.play("open")
	
	var player = GameManager.player
	if player != null and is_instance_valid(player):
		if player.has_method("heal"):
			player.heal(20) 
	
	if item_id == "gold" or item_id == "score":
		GameManager.add_score(item_amount)
	else:
		GameManager.add_item(item_id, item_amount)

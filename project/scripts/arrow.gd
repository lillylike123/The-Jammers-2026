extends Area2D

@export var speed: float = 500.0
@export var damage: int = 15
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var has_hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	age += delta
	if age >= lifetime:
		queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func get_damage() -> int:
	return damage

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body.has_method("take_damage"):
		has_hit = true
		body.take_damage(damage)
		_stick_and_destroy()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	# In case the arrow hits another hurtbox (Area2D) instead of a body directly
	if area.has_method("get_parent") and area.get_parent().has_method("take_damage"):
		has_hit = true
		area.get_parent().take_damage(damage)
		_stick_and_destroy()

func _stick_and_destroy() -> void:
	set_physics_process(false)
	monitoring = false
	# Optional: play a "hit" animation/sprite here before freeing
	await get_tree().create_timer(0.5).timeout
	queue_free()

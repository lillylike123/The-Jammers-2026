extends CharacterBody2D

@export var move_speed: float = 10.0
@export var contact_damage: int = 15
@export var health: int = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_dead: bool = false

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	var player = GameManager.player as CharacterBody2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		if animated_sprite and animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var max_aggro_range: float = 50.0
	
	if distance <= max_aggro_range:
		var direction: Vector2 = Vector2.DOWN # Default direction if perfectly overlapping
		
		if distance > 1.0:
			direction = to_player.normalized()
			
		if distance < 16.0:
			velocity = direction * max(move_speed * 1.5, 35.0) 
		else:
			velocity = direction * move_speed
			
		if animated_sprite and animated_sprite.animation != "walk":
			animated_sprite.play("fly")
		
		if to_player.x != 0:
			animated_sprite.flip_h = to_player.x < 0
	else:
		velocity = Vector2.ZERO
		if animated_sprite and animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()


func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	if !"health" in self:
		self.set("health", 100) 
		
	health = max(health - amount, 0)
	print("Goblin health remaining: ", health)
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("Goblin has died!")
	
	queue_free()
	


func get_damage() -> int:
	return contact_damage


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
		
	if area.has_method("take_damage"):
		area.take_damage(contact_damage)
		
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(contact_damage)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	
	if area.has_method("get_damage"):
		take_damage(area.get_damage())
		
	elif "damage" in area:
		take_damage(area.damage)
		
	elif area.get_parent() and "damage" in area.get_parent():
		take_damage(area.get_parent().damage)

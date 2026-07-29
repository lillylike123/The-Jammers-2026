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
			
		# FIRM OVERLAP FORCE: If very close, force a minimum movement speed 
		# toward the player so the physics engine registers the Area2D collision!
		if distance < 16.0:
			velocity = direction * move_speed#max(move_speed * 1.5, 35.0) 
		else:
			velocity = direction * move_speed
			
		if animated_sprite and animated_sprite.animation != "walk":
			animated_sprite.play("skipping around")
		else:
			animated_sprite.play("angry?")
		
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
		
	# Subtract health (Assuming you have a 'health' variable, if not we will add it)
	if !"health" in self:
		self.set("health", 100) # Quick fallback safety
		
	health = max(health - amount, 0)
	print("Goblin health remaining: ", health)
	
	# Play a flash effect or hurt sound here if you want!
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("Goblin has died!")
	
	# If your goblin has a death animation, play it here.
	# Otherwise, we just remove it from the map immediately:
	queue_free()

	
func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.has_method("take_damage"):
		area.take_damage(contact_damage)

		
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(contact_damage)

		
func _on_hurtbox_area_entered(area: Area2D) -> void:
	# If the goblin is already dead, ignore any extra hits
	if is_dead:
		return
	
	# 1. Check if the thing hitting us has a "get_damage()" method (like your Arrow script)
	if area.has_method("get_damage"):
		take_damage(area.get_damage())
		
	# 2. Check if the thing hitting us has a direct damage property (like your Player script hitbox)
	elif "damage" in area:
		take_damage(area.damage)
		
	# 3. Check if the parent of the area has a damage property (fallback protection)
	elif area.get_parent() and "damage" in area.get_parent():
		take_damage(area.get_parent().damage)

# Add this to the bottom of slime.gd so the player can read its damage!
func get_damage() -> int:
	return contact_damage

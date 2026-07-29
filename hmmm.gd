extends Node2D


movement()

	#move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#if move_input != Vector2.ZERO:
		#facing = _direction_to_string(move_input)

	#if state == State.MOVE:
		#velocity = move_input * speed
		#move_and_slide()
	#else:
		#velocity = Vector2.ZERO

	#if Input.is_action_just_pressed("attack") and state == State.MOVE and _can_attack:
		#_attack()
		

	#_update_animation()
func movement():
	var x_mov= Input.get_action_strength("right")-Input.get_action_strength("left")
	var y_mov= Input.get_action_strength("down")-Input.get_action_strength("up")
	var mov= Vector2(x_mov,y_mov)
	velocity= mov.normalized()*move_speed
	
	if Input.is_action_just_pressed("attack"):
		if $AnimatedSprite2D.animation==("walk_right_sword"):
			$AnimatedSprite2D.play("sword_attack_right")
		elif $AnimatedSprite2D.animation==("walk_left_sword"):
			$AnimatedSprite2D.play("sword_attack_left")
		elif $AnimatedSprite2D.animation==("walk_down_sword"):
			$AnimatedSprite2D.play("sword_attack_down") 
		elif  $AnimatedSprite2D.animation==("walk_up_sword"):
			$AnimatedSprite2D.play("sword_attack_up")
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("attack") and state == State.MOVE and _can_attack:
		_attack()

	_update_animation()

		if x_mov > 0:
			$AnimatedSprite2D.play("walk_right_sword")
		elif x_mov < 0:
			$AnimatedSprite2D.play("walk_left_sword")
		elif y_mov > 0:
			$AnimatedSprite2D.play("walk_down_sword") 
		elif  y_mov<0:
			$AnimatedSprite2D.play("walk_up_sword")
	
	
	move_and_slide()
	
	
	extends CharacterBody2D

signal died

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

@export var speed: float = 55.0
@export var max_health: int = 200
@export var contact_damage: int = 15
@export var aggro_range: float = 260.0
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

var health: int
var state: State = State.IDLE
var _can_attack: bool = true


func _ready() -> void:
	health = max_health
	hitbox.monitoring = false
	hurtbox.monitoring = true
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_update_animation()


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return

	var player: Node2D = GameManager.player
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= aggro_range:
				state = State.CHASE

		State.CHASE:
			if dist > aggro_range * 1.3:
				state = State.IDLE
				velocity = Vector2.ZERO
			elif dist <= attack_range:
				velocity = Vector2.ZERO
				if _can_attack:
					_attack()
			else:
				velocity = to_player.normalized() * speed
				_face_direction(to_player.x)

		State.ATTACK, State.HURT:
			velocity = Vector2.ZERO

	#if state == State.CHASE or state == State.IDLE:
	move_and_slide()

	_update_animation()


func _face_direction(x: float) -> void:
	if x != 0.0:
		animated_sprite.flip_h = x < 0.0


func _update_animation() -> void:
	match state:
		State.IDLE:
			_play("idle")
		State.CHASE:
			_play("walking" if velocity != Vector2.ZERO else "idle")
		State.ATTACK:
			_play("attack")
		State.HURT:
			_play("idle")
			_flash_hurt()
		State.DEAD:
			_play("death")


func _play(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	else:
		push_warning("Boss: missing animation '%s'" % anim_name)


func _attack() -> void:
	state = State.ATTACK
	_can_attack = false
	_update_animation()
	hitbox.monitoring = true
	await get_tree().create_timer(0.3).timeout
	hitbox.monitoring = false
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): _can_attack = true)


func _on_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.CHASE
	elif state == State.DEAD:
		queue_free()


func _flash_hurt() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.4, 0.4), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.08)
	tween.finished.connect(func():
		if state == State.HURT:
			state = State.CHASE
	)


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	
	print("Boss took damage: ", amount)
	print("Damage source trace:")
	print_stack()
	
	health = max(health - amount, 0)
	print("Boss health remaining: ", health)
	
	if health <= 0:
		print("Boss dying!")
		_die()
	elif state != State.ATTACK:
		state = State.HURT
		_update_animation()


func _die() -> void:
	state = State.DEAD
	collision_shape.set_deferred("disabled", true)
	hurtbox.monitoring = false
	hitbox.monitoring = false
	died.emit()
	_update_animation()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == hurtbox or area.get_parent() == self:
		return

	if area.is_in_group("player_hurtbox"):
		var player = area.get_parent()
		if player and player.has_method("take_damage"):
			player.take_damage(contact_damage)
func _on_hurtbox_area_entered(area: Area2D) -> void:
	var dmg := _extract_damage(area)
	if dmg > 0:
		take_damage(dmg)


func _extract_damage(area: Node) -> int:
	if area.has_method("get_damage"):
		return area.get_damage()
	if "damage" in area:
		return area.damage
	var parent := area.get_parent()
	if parent and "damage" in parent:
		return parent.damage
	return 0
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
			animated_sprite.play("right_idle")
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
			animated_sprite.play("walk")
		
		if to_player.x != 0:
			animated_sprite.flip_h = to_player.x < 0
	else:
		velocity = Vector2.ZERO
		if animated_sprite and animated_sprite.animation != "idle":
			animated_sprite.play("right_idle")

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

func get_damage() -> int:
	return contact_damage

	

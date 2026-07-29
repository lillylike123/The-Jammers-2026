extends CharacterBody2D

signal died

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

@export var speed: float = 65.0
@export var max_health: int = 1         # FIXED: Set to exactly 1 HP
@export var contact_damage: int = 40    # High damage to make it a threat!
@export var aggro_range: float = 260.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $hitbox
@onready var hurtbox: Area2D = $hurtbox

var health: int
var state: State = State.IDLE
var _can_attack: bool = true

func _ready() -> void:
	health = max_health
	if hitbox: hitbox.monitoring = false
	if hurtbox: hurtbox.monitoring = true
	
	# Connect signals safely
	if hurtbox and not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
		
	_update_animation()

func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return

	var player = GameManager.player as CharacterBody2D
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return

	var to_player : Vector2 = player.global_position - global_position
	var dist : float = to_player.length()

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
				# FIXED: Only freeze velocity if the boss is actually allowed to strike!
				if _can_attack:
					velocity = Vector2.ZERO
					_attack()
				else:
					# If the attack is on cooldown, keep pressing forward!
					velocity = to_player.normalized() * speed
					_face_direction(to_player.x)
			else:
				velocity = to_player.normalized() * speed
				_face_direction(to_player.x)

		State.ATTACK, State.HURT:
			velocity = Vector2.ZERO

	# Crucial: Ensure move_and_slide runs during ATTACK recovery if needed,
	# but keeping it safe under CHASE/IDLE match bounds
	if state == State.CHASE or state == State.IDLE:
		move_and_slide()

	_update_animation()


func _face_direction(x: float) -> void:
	if x != 0.0 and animated_sprite:
		animated_sprite.flip_h = x < 0.0

func _update_animation() -> void:
	if not animated_sprite: return
	
	match state:
		State.IDLE:
			_play("idle")
		State.CHASE:
			_play("walk" if velocity != Vector2.ZERO else "idle")
		State.ATTACK:
			_play("attack") # Calls your attack animation cleanly
		State.HURT:
			_play("idle")
			_flash_hurt()
		State.DEAD:
			_play("dying")

func _play(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

func _attack() -> void:
	state = State.ATTACK
	_can_attack = false
	_update_animation()
	
	# Turn on attack hitbox frames
	if hitbox: 
		hitbox.monitoring = true
	
	# Wait for the swing window to complete
	await get_tree().create_timer(0.3).timeout
	if hitbox: 
		hitbox.monitoring = false
	
	# SOLID FIX: Force the boss out of the frozen attack state back into chase 
	# mode, even if the animation loops or fails to trigger its finish signal!
	if state == State.ATTACK:
		state = State.CHASE
	
	# Set when they can attempt to strike again
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): _can_attack = true)


func _flash_hurt() -> void:
	if not animated_sprite: return
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
	
	health = max(health - amount, 0)
	print("Boss hit! Remaining health: ", health)
	
	if health <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	if collision_shape: collision_shape.set_deferred("disabled", true)
	if hurtbox: hurtbox.set_deferred("monitoring", false)
	if hitbox: hitbox.set_deferred("monitoring", false)
	died.emit()
	_update_animation()

func get_damage() -> int:
	return contact_damage



func _on_animated_sprite_2d_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.CHASE
	elif state == State.DEAD:
		queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if state == State.DEAD: return
	
	# Read player weapons/arrows
	if area.has_method("get_damage"):
		take_damage(area.get_damage())
	elif "damage" in area:
		take_damage(area.damage)

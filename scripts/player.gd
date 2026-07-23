extends CharacterBody2D

@export var speed: float = 300.0
@export var combo_reset_time: float = 0.6
@export var attack_cooldown: float = 0.25
@export var max_health: int = 100
@export var invincibility_time: float = 0.5

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum Weapon { NONE, SWORD, BOW }

var last_direction: Vector2 = Vector2.DOWN
var combo_step: int = 0
var can_attack: bool = true
var is_attacking: bool = false
var current_health: int
var is_invincible: bool = false
var is_dead: bool = false
var current_weapon: Weapon = Weapon.NONE

var combo_reset_elapsed: float = 0.0
var attack_cooldown_elapsed: float = 0.0
var invincibility_elapsed: float = 0.0
var attack_active_elapsed: float = 0.0
var is_attack_hitbox_active: bool = false

const HITBOX_OFFSET: float = 40.0
const ATTACK_HITBOX_DURATION: float = 0.15

#const ARROW_SCENE: PackedScene = #preload()

signal health_changed(current: int, max: int)
signal weapon_changed(weapon: Weapon)
signal died

func _ready() -> void:
	current_health = max_health

	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)

	hurtbox.monitoring = true
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)

	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if is_dead:
		return

	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_direction = input_direction.normalized()

	if input_direction != Vector2.ZERO:
		last_direction = input_direction
		_update_facing(input_direction)

	if not is_attacking:
		velocity = input_direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if Input.is_action_just_pressed("attack") and can_attack:
		_perform_attack()
		return

	if not is_attacking:
		_update_movement_animation(input_direction)

func _update_timers(delta: float) -> void:
	if is_attacking:
		combo_reset_elapsed = 0.0
	elif combo_step > 0:
		combo_reset_elapsed += delta
		if combo_reset_elapsed >= combo_reset_time:
			combo_step = 0
			combo_reset_elapsed = 0.0

	if not can_attack:
		attack_cooldown_elapsed += delta
		if attack_cooldown_elapsed >= attack_cooldown:
			can_attack = true
			attack_cooldown_elapsed = 0.0

	if is_invincible:
		invincibility_elapsed += delta
		if invincibility_elapsed >= invincibility_time:
			is_invincible = false
			hurtbox.monitoring = true
			invincibility_elapsed = 0.0

	if is_attack_hitbox_active:
		attack_active_elapsed += delta
		if attack_active_elapsed >= ATTACK_HITBOX_DURATION:
			hitbox.monitoring = false
			is_attacking = false
			is_attack_hitbox_active = false
			attack_active_elapsed = 0.0

func _update_facing(direction: Vector2) -> void:
	if direction.x != 0:
		anim.flip_h = direction.x < 0

func _weapon_suffix() -> String:
	match current_weapon:
		Weapon.SWORD:
			return "_sword"
		Weapon.BOW:
			return "_bow"
		_:
			return ""

func _update_movement_animation(input_direction: Vector2) -> void:
	var suffix := _weapon_suffix()
	if input_direction == Vector2.ZERO:
		anim.play("idle" + suffix)
	else:
		anim.play("run" + suffix)

func _perform_attack() -> void:
	
	if current_weapon == Weapon.NONE:
		return

	combo_step += 1
	if combo_step > 2:
		combo_step = 1

	is_attacking = true
	can_attack = false
	attack_cooldown_elapsed = 0.0

	if current_weapon == Weapon.BOW:
		_fire_arrow()
		anim.play("atk" + str(combo_step) + "_bow")
	else:
		_position_hitbox()
		hitbox.monitoring = true
		hitbox.scale = Vector2(1.2, 1.2) if combo_step == 2 else Vector2(1.0, 1.0)
		is_attack_hitbox_active = true
		attack_active_elapsed = 0.0
		anim.play("atk" + str(combo_step) + "_sword")

func _position_hitbox() -> void:
	hitbox.position = last_direction * HITBOX_OFFSET
	hitbox.rotation = last_direction.angle()

func _fire_arrow() -> void:
	if not ARROW_SCENE:
		return
	var arrow := ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = global_position + last_direction * HITBOX_OFFSET
	arrow.rotation = last_direction.angle()
	if arrow.has_method("set_direction"):
		arrow.set_direction(last_direction)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var damage: int = 10 if combo_step == 1 else 18
		body.take_damage(damage)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		take_damage(area.get_damage())
	elif "damage" in area:
		take_damage(area.damage)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.has_method("get_contact_damage"):
		take_damage(body.get_contact_damage())

func take_damage(amount: int) -> void:
	if is_invincible or is_dead:
		return

	current_health -= amount
	current_health = max(current_health, 0)
	health_changed.emit(current_health, max_health)
	print("Player took ", amount, " damage. HP: ", current_health, "/", max_health)

	if current_health <= 0:
		_die()
		return

	is_invincible = true
	invincibility_elapsed = 0.0
	hurtbox.monitoring = false

	anim.play("hurt" + _weapon_suffix())

func _on_animation_finished() -> void:
	var name := anim.animation
	if name.begins_with("atk") or name.begins_with("hurt"):
		if not is_dead:
			_update_movement_animation(velocity.normalized() if velocity != Vector2.ZERO else Vector2.ZERO)

func _die() -> void:
	is_dead = true
	hitbox.monitoring = false
	hurtbox.monitoring = false
	velocity = Vector2.ZERO
	anim.play("death")
	died.emit()
	print("Player died")

func pick_up_weapon(weapon_name: String) -> void:
	match weapon_name.to_lower():
		"sword":
			current_weapon = Weapon.SWORD
		"bow":
			current_weapon = Weapon.BOW
		_:
			return
	weapon_changed.emit(current_weapon)
	print("Picked up: ", weapon_name)

func drop_weapon() -> void:
	current_weapon = Weapon.NONE
	weapon_changed.emit(current_weapon)

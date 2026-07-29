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

	if state == State.CHASE or state == State.IDLE:
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
	health = max(health - amount, 0)
	if health <= 0:
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
	if area.has_method("take_damage"):
		area.take_damage(contact_damage)
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(contact_damage)


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

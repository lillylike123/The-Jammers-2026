extends CharacterBody2D


signal hurt(current_health: int, max_health: int)
signal died

enum State { MOVE, ATTACK, HURT, DEAD }

@export var speed: float = 130.0
@export var max_health: int = 100
@export var sword_damage: int = 20
@export var arrow_scene: PackedScene   = preload("res://scenes/arrow.tscn")
@export var attack_cooldown: float = 0.35

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

var health: int
var state: State = State.MOVE
var facing: String = "down"
var move_input: Vector2 = Vector2.ZERO
var _can_attack: bool = true


func _ready() -> void:
	health = max_health
	hitbox.monitoring = false
	hurtbox.monitoring = true
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	GameManager.register_player(self)
	_update_animation()


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return

	move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input != Vector2.ZERO:
		facing = _direction_to_string(move_input)

	if state == State.MOVE:
		velocity = move_input * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("attack") and state == State.MOVE and _can_attack:
		_attack()

	_update_animation()


func _direction_to_string(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"


func _update_animation() -> void:
	match state:
		State.MOVE:
			if move_input != Vector2.ZERO:
				_play(_walk_anim_name())
			else:
				
				_play(_walk_anim_name())
				animated_sprite.stop()
				animated_sprite.frame = 0
		State.ATTACK:
			_play(_attack_anim_name())
		State.HURT:
			
			_play(_walk_anim_name())
			_flash_hurt()
		State.DEAD:
			
			_play(_walk_anim_name())
			animated_sprite.stop()
			_fade_out_and_die()


#
func _walk_anim_name() -> String:
	var weapon_suffix := "_sword" if GameManager.selected_weapon == GameManager.Weapon.SWORD else "_bow"
	match facing:
		"left": return "walk_left" + weapon_suffix
		"right": return "walk_right" + weapon_suffix
		"up": return "walk_up"
		_: return "walk_down"


## sword_attack_down/up/left/right, bow_attack_down/up/left/right
func _attack_anim_name() -> String:
	var weapon_prefix := "sword_attack_" if GameManager.selected_weapon == GameManager.Weapon.SWORD else "bow_attack_"
	return weapon_prefix + facing


func _play(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		push_warning("Player: missing animation '%s'" % anim_name)


func _attack() -> void:
	state = State.ATTACK
	_can_attack = false
	_update_animation()
	if GameManager.selected_weapon == GameManager.Weapon.SWORD:
		_sword_attack()
	else:
		_bow_attack()
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): _can_attack = true)


func _sword_attack() -> void:
	hitbox.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hitbox.monitoring = false


func _bow_attack() -> void:
	if arrow_scene == null:
		push_warning("Player: assign an Arrow scene in the Inspector to fire arrows.")
		return
	var arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	var dir := _facing_vector()
	arrow.global_position = global_position + dir * 16  
	arrow.z_index = 1                                    
	arrow.direction = dir


func _facing_vector() -> Vector2:
	match facing:
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
		"up": return Vector2.UP
		_: return Vector2.DOWN


func _on_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.MOVE


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health = max(health - amount, 0)
	hurt.emit(health, max_health)
	if health <= 0:
		_die()
	else:
		state = State.HURT
		_update_animation()


func _die() -> void:
	state = State.DEAD
	collision_shape.set_deferred("disabled", true)
	hurtbox.monitoring = false
	_update_animation()
	died.emit()


func _flash_hurt() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.4, 0.4), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.4, 0.4), 0.08)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.08)
	tween.finished.connect(func():
		if state == State.HURT:
			state = State.MOVE
	)


func _fade_out_and_die() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.6)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(sword_damage)
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(sword_damage)


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

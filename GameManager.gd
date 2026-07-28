extends Node


enum Weapon { SWORD, BOW }

signal weapon_changed(weapon: int)
signal player_health_changed(current: int, max: int)
signal player_died
signal game_paused(is_paused: bool)

var selected_weapon: Weapon = Weapon.SWORD

var player: Node = null

var score: int = 0
var inventory: Dictionary = {}


func register_player(p: Node) -> void:
	player = p

	if player.has_signal("hurt") and not player.hurt.is_connected(_on_player_hurt):
		player.hurt.connect(_on_player_hurt)

	if player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)


func unregister_player(p: Node) -> void:
	if player == p:
		player = null


func _on_player_hurt(current_health: int, max_health: int) -> void:
	player_health_changed.emit(current_health, max_health)


func _on_player_died() -> void:
	player_died.emit()
	# Hook your game-over flow here, e.g.:
	# get_tree().paused = true
	# get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func set_weapon(weapon: Weapon) -> void:
	if selected_weapon == weapon:
		return
	selected_weapon = weapon
	weapon_changed.emit(weapon)


func toggle_weapon() -> void:
	set_weapon(Weapon.BOW if selected_weapon == Weapon.SWORD else Weapon.SWORD)


func add_score(amount: int) -> void:
	score += amount


func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount


func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount


func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true


func pause_game(paused: bool) -> void:
	get_tree().paused = paused
	game_paused.emit(paused)


func reset_game_state() -> void:
	score = 0
	inventory.clear()
	selected_weapon = Weapon.SWORD
	player = null

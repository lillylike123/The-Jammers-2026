extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var timer_label: Label = $TimerLabel

# 10 minutes converted cleanly to total floating seconds (10 * 60)
var time_left: float = 600.0
var is_timer_active: bool = false

func _ready() -> void:
	# 1. Connect to global GameManager signals
	GameManager.player_health_changed.connect(_on_player_health_changed)
	GameManager.player_died.connect(_on_player_died)
	
	# 2. Hook into the scene tree so we can detect when safe rooms load/unload
	get_tree().node_added.connect(_on_node_added)
	
	if GameManager.player != null and is_instance_valid(GameManager.player):
		_on_player_health_changed(GameManager.player.health, GameManager.player.max_health)
		
	# 3. RULE: Keep the HUD completely hidden and paused by default on startup
	is_timer_active = false
	visible = false 

func _process(delta: float) -> void:
	# Only countdown if the timer is actively running and unpaused
	if not is_timer_active or not visible:
		return
		
	if time_left > 0.0:
		time_left -= delta
		_update_timer_display()
	else:
		time_left = 0.0
		is_timer_active = false
		_on_time_expired()

## RULE: Call this function from your Weapon Selection script's select button callback!
func start_hud() -> void:
	time_left = 600.0       # Initialize to exactly 10 minutes
	is_timer_active = true   # Start the clock ticker
	visible = true           # RULE: Make it visible now that the game started
	_update_timer_display()  # Force an instant numbers refresh

## Translates raw countdown seconds into a readable "MM:SS" format string
func _update_timer_display() -> void:
	if not timer_label: return
	
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	
	# The %02d formatting rule guarantees leading zeros (e.g., "09:05")
	timer_label.text = "%02d:%02d" % [minutes, seconds]


## Triggers the moment the 10-minute clock hits absolute zero
func _on_time_expired() -> void:
	print("HUD Timer: Time has run out! Triggering Game Over.")
	if GameManager.player != null and is_instance_valid(GameManager.player):
		if GameManager.player.has_method("take_damage"):
			GameManager.player.take_damage(9999) # Instant absolute kill factor

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		var tween := create_tween()
		tween.tween_property(health_bar, "value", current_health, 0.25).set_trans(Tween.TRANS_SINE)

func _on_player_died() -> void:
	if health_bar:
		health_bar.value = 0
	is_timer_active = false

## Call this if the player quits to the Main Menu manually to wipe UI properties completely
func hide_and_reset_hud() -> void:
	is_timer_active = false
	visible = false
	time_left = 600.0

func _on_node_added(node: Node) -> void:
	# Ignore checking if the player is still sitting in the main menus
	if not visible:
		return
		
	# Wait until the node attached is a primary 2D map node
	if node is Node2D:
		# Check if the loading level file name belongs to your safe room
		if node.scene_file_path.ends_with("safe_room.tscn"):
			is_timer_active = false
			print("HUD Timer: Safe Room detected via node tree! Countdown PAUSED.")
		# Resume the clock for normal combat fields and the final boss arena
		elif node.scene_file_path.ends_with(".tscn"):
			is_timer_active = true
			print("HUD Timer: Gameplay room detected. Countdown RESUMED.")

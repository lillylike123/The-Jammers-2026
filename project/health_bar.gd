extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var timer_label: Label = $TimerLabel

var time_left: float = 600.0
var is_timer_active: bool = false

func _ready() -> void:
	GameManager.player_health_changed.connect(_on_player_health_changed)
	GameManager.player_died.connect(_on_player_died)
	
	get_tree().node_added.connect(_on_node_added)
	
	if GameManager.player != null and is_instance_valid(GameManager.player):
		_on_player_health_changed(GameManager.player.health, GameManager.player.max_health)
		
	is_timer_active = false
	visible = false 

func _process(delta: float) -> void:
	if not is_timer_active or not visible:
		return
		
	if time_left > 0.0:
		time_left -= delta
		_update_timer_display()
	else:
		time_left = 0
		is_timer_active = false
		_on_time_expired()
										 
func start_hud() -> void:
	time_left = 600.0       
	is_timer_active = true   
	visible = true           
	_update_timer_display() 

func _update_timer_display() -> void:
	if not timer_label: return
	
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _on_time_expired() -> void:
	print("HUD Timer: Time has run out! Triggering Game Over.")
	if GameManager.player != null and is_instance_valid(GameManager.player):
		if GameManager.player.has_method("take_damage"):
			GameManager.player.take_damage(9999) 

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		var tween := create_tween()
		tween.tween_property(health_bar, "value", current_health, 0.25).set_trans(Tween.TRANS_SINE)

func _on_player_died() -> void:
	if health_bar:
		health_bar.value = 0
	is_timer_active = false

func hide_and_reset_hud() -> void:
	is_timer_active = false
	visible = false
	time_left = 600.0

func _on_node_added(node: Node) -> void:
	if not visible:
		return
		
	if node is Node2D:
		if node.scene_file_path.ends_with("safe_room.tscn"):
			is_timer_active = false
			print("HUD Timer: Safe Room detected via node tree! Countdown PAUSED.")
		elif node.scene_file_path.ends_with(".tscn"):
			is_timer_active = true
			print("HUD Timer: Gameplay room detected. Countdown RESUMED.")

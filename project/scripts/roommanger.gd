extends Node

# 1. DEFINE YOUR EXACT LEVEL ROADMAP
@export var combat_maps: Array[String] = [
	"res://scenes/map1.tscn",
	"res://scenes/map_2.tscn",
	"res://scenes/map_3.tscn",
	"res://scenes/map4.tscn",
	"res://scenes/map_5.tscn",
	"res://scenes/map_6.tscn"
]

@export var safe_room_scene: String = "res://scenes/saferoom.tscn"
@export var boss_room_scene: String = "res://scenes/cave.tscn"

# 2. RUN STATE PROGRESSION MEMORY
var rooms_cleared_total: int = 0
var visited_combat_maps: Array[String] = []

## Call this function from any Door/Portal to load the next step of the journey
func load_next_room() -> void:
	# Add 1 to our running room tally
	rooms_cleared_total += 1
	print("--- Room Manager Progression: Step #", rooms_cleared_total, " ---")
	
	var target_scene_path: String = ""

	# CONDITION A: Exactly at Step 3 -> Serve up the Safe Room!
	if rooms_cleared_total == 3:
		print("RoomManager: Halfway point hit. Transitioning to SAFE ROOM.")
		target_scene_path = safe_room_scene
		
	# CONDITION B: Exactly at Step 7 -> All 6 combat zones + 1 safe zone completed! Time for the Boss!
	elif rooms_cleared_total == 7:
		print("RoomManager: Run climax reached! Transitioning to final BOSS ROOM.")
		target_scene_path = boss_room_scene
		
	# CONDITION C: Load a fresh, unvisited combat map
	else:
		target_scene_path = _get_unvisited_combat_map()

	# Execute a safe deferred scene change to protect the physics engine thread
	if target_scene_path != "":
		print("RoomManager: Safely calling load for -> ", target_scene_path)
		get_tree().call_deferred("change_scene_to_file", target_scene_path)
	else:
		push_error("RoomManager: Failed to calculate valid scene string choice!")

## Picks a unique combat map from the pool so the player never sees duplicates
func _get_unvisited_combat_map() -> String:
	var available_maps: Array[String] = []
	
	# Gather only the maps the player hasn't stepped into yet
	for map_path in combat_maps:
		if not visited_combat_maps.has(map_path):
			available_maps.append(map_path)
			
	# Emergency fallback if something clears the memory out of order
	if available_maps.is_empty():
		push_warning("RoomManager: Map array unexpectedly exhausted early. Re-cycling pool.")
		visited_combat_maps.clear()
		available_maps = combat_maps.duplicate()
		
	# Select a truly random map index from our remaining unique pool
	var random_index: int = randi() % available_maps.size()
	var chosen_map: String = available_maps[random_index]
	
	# Log this specific map path to memory so it doesn't duplicate
	visited_combat_maps.append(chosen_map)
	return chosen_map

## Call this whenever the player wins the run or returns to the Main Menu to reset counters
func reset_run_state() -> void:
	rooms_cleared_total = 0
	visited_combat_maps.clear()
	print("RoomManager: Run state counters wiped clean.")

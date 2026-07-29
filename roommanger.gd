extends Node

# A list of all your game maps. Add your scene paths here!
@export var map_pool: Array[String] = [
	"res://scenes/map1.tscn",
	"res://scenes/map_2.tscn",
	"res://scenes/map_3.tscn",
	"res://scenes/map4.tscn",
	"res://scenes/map_5.tscn",
	"res://scenes/map_6.tscn",
]

# Track maps that have already been visited so we don't repeat them immediately
var visited_maps: Array[String] = []

## Selects a new map from the pool and switches to it
func load_next_random_room() -> void:
	# Fallback if the map pool is accidentally empty
	if map_pool.is_empty():
		push_error("RoomManager: No maps added to the map pool!")
		return

	# Reset the pool cycle if the player has seen all rooms
	if visited_maps.size() >= map_pool.size():
		visited_maps.clear()

	# Filter out maps we have already visited in this loop cycle
	var available_maps: Array[String] = []
	for map_path in map_pool:
		if not visited_maps.has(map_path):
			available_maps.append(map_path)

	# Pick a truly random room from the remaining choices
	var random_index: int = randi() % available_maps.size()
	var next_map_path: String = available_maps[random_index]

	# Log this map as visited
	visited_maps.append(next_map_path)

	# Print to debugger console for easy tracking
	print("RoomManager: Moving to random room -> ", next_map_path)

	# Safely transition the scene tree
	get_tree().call_deferred("change_scene_to_file", next_map_path)

extends Node

@export var map_pool: Array[String] = [
	"res://scenes/map1.tscn",
	"res://scenes/map_2.tscn",
	"res://scenes/map_3.tscn",
	"res://scenes/map4.tscn",
	"res://scenes/map_5.tscn",
	"res://scenes/map_6.tscn",
]

var visited_maps: Array[String] = []

func load_next_random_room() -> void:
	if map_pool.is_empty():
		push_error("RoomManager: No maps added to the map pool!")
		return

	if visited_maps.size() >= map_pool.size():
		visited_maps.clear()

	var available_maps: Array[String] = []
	for map_path in map_pool:
		if not visited_maps.has(map_path):
			available_maps.append(map_path)

	var random_index: int = randi() % available_maps.size()
	var next_map_path: String = available_maps[random_index]

	visited_maps.append(next_map_path)

	print("RoomManager: Moving to random room -> ", next_map_path)

	get_tree().call_deferred("change_scene_to_file", next_map_path)

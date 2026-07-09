extends Node3D
class_name MapRenderer

signal tile_selected(tile: Dictionary)

@export var tile_size := 2.0
@export var show_labels := true

var _materials: Dictionary = {}


func render_world(maps: Array[Dictionary]) -> void:
	_clear_children()
	for tile in maps:
		_add_tile(tile)


func grid_to_world(tile: Dictionary) -> Vector3:
	var x := float(tile.get("x", 0))
	var y := float(tile.get("y", 0))
	var layer := str(tile.get("layer", "overworld"))
	return Vector3(x * tile_size, _layer_height(layer), y * tile_size)


func _add_tile(tile: Dictionary) -> void:
	var tile_body := StaticBody3D.new()
	tile_body.name = "Tile_%s_%s_%s" % [tile.get("layer", "layer"), tile.get("x", 0), tile.get("y", 0)]
	tile_body.position = grid_to_world(tile)
	tile_body.input_ray_pickable = true
	tile_body.input_event.connect(_on_tile_input.bind(tile))
	add_child(tile_body)

	var content_type := _content_type(tile)
	var height := _height_for_content(content_type)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(tile_size * 0.94, height, tile_size * 0.94)
	mesh.mesh = box
	mesh.position.y = height * 0.5
	mesh.material_override = _material_for_content(content_type, str(tile.get("skin", "")))
	tile_body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(tile_size * 0.94, max(height, 0.2), tile_size * 0.94)
	shape.shape = box_shape
	shape.position.y = max(height, 0.2) * 0.5
	tile_body.add_child(shape)

	if show_labels:
		_add_label(tile_body, tile, height)


func _add_label(parent: Node3D, tile: Dictionary, height: float) -> void:
	var label := Label3D.new()
	var content_code := _content_code(tile)
	label.text = content_code if not content_code.is_empty() else str(tile.get("map_id", "tile"))
	label.font_size = 24
	label.position = Vector3(0.0, height + 0.35, 0.0)
	label.rotation_degrees.x = -65.0
	parent.add_child(label)


func _content_type(tile: Dictionary) -> String:
	var direct := str(tile.get("content_type", ""))
	if not direct.is_empty():
		return direct

	var interactions := tile.get("interactions", {})
	if interactions is Dictionary:
		var content := interactions.get("content", {})
		if content is Dictionary:
			return str(content.get("type", "terrain"))
	return "terrain"


func _content_code(tile: Dictionary) -> String:
	var direct := str(tile.get("content_code", ""))
	if not direct.is_empty():
		return direct

	var interactions := tile.get("interactions", {})
	if interactions is Dictionary:
		var content := interactions.get("content", {})
		if content is Dictionary:
			return str(content.get("code", ""))
	return ""


func _height_for_content(content_type: String) -> float:
	match content_type:
		"bank":
			return 0.26
		"grand_exchange":
			return 0.32
		"monster":
			return 0.22
		"resource":
			return 0.18
		"npc", "task":
			return 0.2
		"raid", "event":
			return 0.36
		_:
			return 0.12


func _material_for_content(content_type: String, skin: String) -> StandardMaterial3D:
	var key := content_type if not content_type.is_empty() else skin
	if key.is_empty():
		key = "terrain"
	if _materials.has(key):
		return _materials[key]

	var material := StandardMaterial3D.new()
	match key:
		"bank":
			material.albedo_color = Color(0.28, 0.44, 0.95)
		"grand_exchange":
			material.albedo_color = Color(0.96, 0.72, 0.2)
		"monster":
			material.albedo_color = Color(0.8, 0.24, 0.22)
		"resource":
			material.albedo_color = Color(0.2, 0.62, 0.36)
		"npc", "task":
			material.albedo_color = Color(0.7, 0.5, 0.95)
		"raid":
			material.albedo_color = Color(0.55, 0.2, 0.85)
		"event":
			material.albedo_color = Color(0.95, 0.45, 0.15)
		_:
			material.albedo_color = Color(0.18, 0.42, 0.2)
	_materials[key] = material
	return material


func _layer_height(layer: String) -> float:
	match layer:
		"underground":
			return -0.35
		"sky":
			return 0.55
		_:
			return 0.0


func _on_tile_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, tile: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tile_selected.emit(tile)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
